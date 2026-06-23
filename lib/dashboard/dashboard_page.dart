import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:suez_admin/authentication/guards/AuthGuard.dart';
import 'package:suez_admin/theme/app_color.dart';
import 'package:suez_admin/commission/services/commission_admin_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalStores = 0;
  int _activeStores = 0;
  int _inactiveStores = 0;
  int _totalProducts = 0;
  int _productsAddedToday = 0;
  int _totalCommissions = 0;
  int _pendingDepositRequests = 0;
  int _storesNearCreditLimit = 0;
  int _negativeBalanceStores = 0;

  // إحصائيات الطلبات المتقدمة
  int _todayTotalOrders = 0;
  int _todayCompletedOrders = 0;
  int _todayCancelledOrders = 0;
  double _todayCommissions = 0.0;
  int _totalOrders = 0;

  bool _isLoading = true;
  final CommissionAdminService _commissionService = CommissionAdminService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isCompletedOrder(Map<String, dynamic> data) {
    final orderStatus = (data['orderStatus'] ?? '').toString();
    final lifecycle = (data['lifecycleStatus'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    if (orderStatus == 'completed') return true;
    if (lifecycle == 'fulfilled') return true;
    if (status == 'تم التسليم للطيار' || status == 'تم التسليم') return true;
    if (status.toLowerCase() == 'delivered' ||
        status.toLowerCase() == 'completed') {
      return true;
    }
    final deliveryStatus =
        (data['deliveryRequest']?['status'] ?? '').toString();
    if (deliveryStatus == 'completed') return true;
    return false;
  }

  bool _isCancelledOrder(Map<String, dynamic> data) {
    if (data['cancelReason'] != null &&
        data['cancelReason'].toString().isNotEmpty) {
      return true;
    }
    final orderStatus = (data['orderStatus'] ?? '').toString();
    final status = (data['status'] ?? '').toString();
    final lifecycle = (data['lifecycleStatus'] ?? '').toString();
    const cancelStatuses = {
      'cancelled',
      'cancelled_by_customer',
      'cancelled_by_merchant',
      'rejected',
    };
    if (cancelStatuses.contains(orderStatus)) return true;
    if (cancelStatuses.contains(status)) return true;
    if (lifecycle == 'cancelled') return true;
    if (status.contains('إلغاء') || status.contains('رفض')) return true;
    return false;
  }

  double _toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  Future<void> _loadDashboardData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // جلب جميع المتاجر
      final storesSnapshot = await _firestore.collection('markets').get();

      if (!mounted) return;
      _totalStores = storesSnapshot.docs.length;
      _activeStores = 0;
      _inactiveStores = 0;

      // حساب المتاجر النشطة وغير النشطة
      for (var doc in storesSnapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'] == true;

        if (isActive) {
          _activeStores++;
        } else {
          _inactiveStores++;
        }
      }

      // حساب عدد المنتجات الفعلي لكل متجر وتحديثه في قاعدة البيانات
      int totalProductsSum = 0;
      final futures = storesSnapshot.docs.map((doc) async {
        final marketId = doc.id;
        final data = doc.data();
        try {
          final countSnap = await _firestore
              .collectionGroup('items')
              .where('marketId', isEqualTo: marketId)
              .count()
              .get();
          final actualProducts = countSnap.count ?? 0;

          if (data['totalProducts'] != actualProducts) {
            await _firestore.collection('markets').doc(marketId).update({
              'totalProducts': actualProducts,
            });
          }
          return actualProducts;
        } catch (e) {
          print('خطأ في جلب عدد المنتجات الفعلي للمتجر $marketId: $e');
          return data['totalProducts'] as int? ?? 0;
        }
      });

      final counts = await Future.wait(futures);
      for (final count in counts) {
        totalProductsSum += count;
      }
      _totalProducts = totalProductsSum;

      // حساب المنتجات المضافة اليوم
      await _calculateProductsAddedToday(storesSnapshot.docs);

      // حساب إحصائيات الطلبات
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 1. عدد الطلبات الإجمالي
      final totalOrdersSnap = await _firestore.collection('orders').count().get();
      _totalOrders = totalOrdersSnap.count ?? 0;

      // 2. طلبات اليوم
      final todayOrdersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      int todayTotal = 0;
      int todayCompleted = 0;
      int todayCancelled = 0;
      double todayComm = 0.0;

      for (var doc in todayOrdersSnapshot.docs) {
        final data = doc.data();
        todayTotal++;
        if (_isCompletedOrder(data)) {
          todayCompleted++;
          todayComm += _toD(data['serviceFee']);
        } else if (_isCancelledOrder(data)) {
          todayCancelled++;
        }
      }

      _todayTotalOrders = todayTotal;
      _todayCompletedOrders = todayCompleted;
      _todayCancelledOrders = todayCancelled;
      _todayCommissions = todayComm;

      await _loadCommissionStats();

      if (!mounted) return;
      setState(() => _isLoading = false);
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('خطأ في تحميل بيانات لوحة التحكم: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCommissionStats() async {
    try {
      final stats = await _commissionService.getCommissionStats();
      final pendingDeposits = await _firestore
          .collection('wallet_transactions')
          .where('status', isEqualTo: 'pending')
          .get();
      final nearCredit = await _commissionService.getStoresNearCreditLimitCount();
      final negative = await _commissionService.getNegativeBalanceStoresCount();
      if (!mounted) return;
      setState(() {
        _totalCommissions = stats['total'] ?? 0;
        _pendingDepositRequests = pendingDeposits.docs.length;
        _storesNearCreditLimit = nearCredit;
        _negativeBalanceStores = negative;
      });
    } catch (e) {
      print('خطأ في تحميل إحصائيات العمولات: $e');
    }
  }

  Future<void> _calculateProductsAddedToday(
    List<QueryDocumentSnapshot> stores,
  ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      int productsAddedToday = 0;

      // فحص كل متجر
      for (var storeDoc in stores) {
        if (!mounted) return;
        final marketId = storeDoc.id;

        try {
          // جلب جميع فئات المنتجات في المتجر
          final categoriesSnapshot = await _firestore
              .collection('markets')
              .doc(marketId)
              .collection('products')
              .get();

          if (!mounted) return;

          // فحص كل فئة
          for (var categoryDoc in categoriesSnapshot.docs) {
            if (!mounted) return;
            final categoryId = categoryDoc.id;

            try {
              // جلب المنتجات في هذه الفئة
              final productsSnapshot = await _firestore
                  .collection('markets')
                  .doc(marketId)
                  .collection('products')
                  .doc(categoryId)
                  .collection('items')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
                  )
                  .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
                  .get();

              if (!mounted) return;
              productsAddedToday += productsSnapshot.docs.length;
            } catch (e) {
              print('خطأ في جلب منتجات الفئة $categoryId: $e');
            }
          }
        } catch (e) {
          print('خطأ في جلب فئات المتجر $marketId: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _productsAddedToday = productsAddedToday;
      });
    } catch (e) {
      print('خطأ في حساب المنتجات المضافة اليوم: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authGuard = context.watch<AuthGuard>();

    if (authGuard.userStatus != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('غير مصرح'),
          backgroundColor: AppColors.mainColor,
        ),
        body: const Center(child: Text('غير مصرح لك بالوصول إلى هذه الصفحة')),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.mainColor,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.mainColor.withOpacity(0.05),
                Colors.white,
                AppColors.mainColor.withOpacity(0.03),
              ],
            ),
          ),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAnimatedAppBar(),
              SliverToBoxAdapter(
                child: _isLoading
                    ? Container(
                        height: MediaQuery.of(context).size.height - 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.mainColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'جاري تحميل البيانات...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildWelcomeSection(),
                                const SizedBox(height: 24),
                                _buildTodayStatsSection(),
                                const SizedBox(height: 24),
                                _buildMainStatsGrid(),
                                const SizedBox(height: 24),
                                _buildStoresDistributionCard(),
                                const SizedBox(height: 24),
                                _buildProductsSection(),
                                const SizedBox(height: 24),
                                _buildCommissionOverviewSection(),
                                const SizedBox(height: 24),
                                _buildQuickActions(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.mainColor,
              AppColors.mainColor.withOpacity(0.8),
              const Color(0xFF3D7A8F),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.mainColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FlexibleSpaceBar(
          centerTitle: true,
          title: const Text(
            'لوحة التحكم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          background: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -50,
                bottom: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadDashboardData,
            tooltip: 'تحديث',
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting = 'مساء الخير';
    IconData greetingIcon = Icons.wb_twilight;

    if (hour < 12) {
      greeting = 'صباح الخير';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'مساء الخير';
      greetingIcon = Icons.wb_cloudy;
    } else {
      greeting = 'مساء الخير';
      greetingIcon = Icons.nights_stay;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mainColor.withOpacity(0.1),
            AppColors.mainColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.mainColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mainColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(greetingIcon, color: AppColors.mainColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إليك نظرة عامة على نشاط المتاجر والطلبات',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.today_rounded, color: AppColors.mainColor, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'نشاط وحركة اليوم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.35,
          children: [
            _buildTodayStatCard(
              title: 'طلبات اليوم',
              value: _todayTotalOrders.toString(),
              icon: Icons.shopping_bag_rounded,
              color: const Color(0xFF3498DB),
              subtitle: 'إجمالي الطلبات اليوم',
            ),
            _buildTodayStatCard(
              title: 'الطلبات المكتملة',
              value: _todayCompletedOrders.toString(),
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF2ECC71),
              subtitle: 'تم توصيلها اليوم',
            ),
            _buildTodayStatCard(
              title: 'الطلبات الملغاة',
              value: _todayCancelledOrders.toString(),
              icon: Icons.cancel_rounded,
              color: const Color(0xFFE74C3C),
              subtitle: 'ملغاة اليوم',
            ),
            _buildTodayStatCard(
              title: 'عمولات اليوم',
              value: '${_todayCommissions.toStringAsFixed(1)} ج.م',
              icon: Icons.payments_rounded,
              color: const Color(0xFFF1C40F),
              subtitle: 'أرباح اليوم',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              left: -15,
              top: -15,
              child: CircleAvatar(
                radius: 35,
                backgroundColor: color.withOpacity(0.05),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Icon(
                icon,
                color: color.withOpacity(0.15),
                size: 45,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEnhancedStatCard(
                icon: Icons.store_rounded,
                title: 'إجمالي المتاجر',
                value: _totalStores.toString(),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4E99B4), Color(0xFF3D7A8F)],
                ),
                delay: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnhancedStatCard(
                icon: Icons.shopping_cart_checkout_rounded,
                title: 'إجمالي الطلبات',
                value: _totalOrders.toString(),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                ),
                delay: 50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnhancedStatCard(
                icon: Icons.inventory_2_rounded,
                title: 'إجمالي المنتجات',
                value: _totalProducts.toString(),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                ),
                delay: 100,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Gradient gradient,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(-5, -5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresDistributionCard() {
    final total = _totalStores > 0 ? _totalStores : 1;
    final activePercentage = (_activeStores / total);
    final inactivePercentage = (_inactiveStores / total);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.mainColor.withOpacity(0.2),
                        AppColors.mainColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    color: AppColors.mainColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'توزيع المتاجر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStoreDistributionItem(
                    'المفعلة',
                    _activeStores,
                    activePercentage,
                    const Color(0xFF4CAF50),
                    Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStoreDistributionItem(
                    'غير المفعلة',
                    _inactiveStores,
                    inactivePercentage,
                    const Color(0xFFEF5350),
                    Icons.cancel_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildProgressBar(activePercentage),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreDistributionItem(
    String label,
    int count,
    double percentage,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double activePercentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نسبة التفعيل',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7F8C8D),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: activePercentage),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: const Color(0xFFEF5350).withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4CAF50),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _productsAddedToday.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المنتجات المضافة اليوم',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'جديد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.mainColor.withOpacity(0.2),
                        AppColors.mainColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: AppColors.mainColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'إجراءات سريعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                context.go('/admin/sales-analytics');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تحليلات المبيعات والنشاط',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'عرض مبيعات كل متجر ونشاط كل مندوب بالتفصيل',
                            style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.mainColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                context.go('/admin/commission-settings');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.settings_suggest_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عمولة التطبيق',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ضبط رسوم الخدمة لكل المتاجر دفعة واحدة',
                            style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.mainColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                context.go('/admin/wallet-management');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة طلبات الشحن',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'الموافقة أو الرفض لطلبات شحن المحفظة',
                            style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.mainColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                context.go('/admin/ads');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.mainColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة الإعلانات',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'تحكم في إعلانات الصفحة الرئيسية',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.mainColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                context.go('/admin/offices');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.mainColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة مكاتب الشحن',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'إضافة وتعديل وإدارة مكاتب الشحن',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.mainColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                context.go('/admin/courier-requests');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.mainColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.motorcycle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلبات تسجيل المناديب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'مراجعة وقبول أو رفض طلبات المناديب الجدد',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.mainColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                context.go('/admin/reports');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.mainColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.report_gmailerrorred_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة البلاغات',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'مراجعة البلاغات المقدمة من المستخدمين واتخاذ إجراءات بشأنها',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.mainColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص العمولات والمحفظة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _metricRow('إجمالي العمولات', _totalCommissions.toString()),
          _metricRow('طلبات الشحن المعلقة', _pendingDepositRequests.toString()),
          _metricRow('متاجر قريبة من الحد الائتماني', _storesNearCreditLimit.toString()),
          _metricRow('متاجر برصيد سالب', _negativeBalanceStores.toString()),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
