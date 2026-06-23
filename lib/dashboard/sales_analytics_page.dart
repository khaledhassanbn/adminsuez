import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:suez_admin/authentication/guards/AuthGuard.dart';
import 'package:suez_admin/theme/app_color.dart';
import 'package:go_router/go_router.dart';

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = '30days'; // today, 7days, 30days, all
  bool _isLoading = true;

  List<Map<String, dynamic>> _allStores = [];
  List<Map<String, dynamic>> _filteredStores = [];

  List<Map<String, dynamic>> _allDrivers = [];
  List<Map<String, dynamic>> _filteredDrivers = [];

  // تتبع العناصر الموسعة (ID المتجر أو ID المندوب -> bool)
  final Map<String, bool> _expandedItems = {};

  // تتبع الصفحة الحالية للفواتير الموسعة لكل متجر أو مندوب
  final Map<String, int> _currentPageMap = {};
  static const int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      _searchController.clear();
      _filterLists();
      setState(() {
        _expandedItems.clear();
        _currentPageMap.clear();
      });
    });
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  double _toD(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (value is DateTime) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. جلب بيانات مناديب مكاتب الشحن من مجموعة users
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .get();
      final Map<String, bool> officeDriverSuspendedMap = {};
      final Set<String> officeDriverUids = {};
      final Map<String, String> officeDriverNameToUid = {};
      final Map<String, String> officeDriverPhoneToUid = {};
      final Map<String, String> officeDriverUidToNameMap = {};

      for (var doc in usersSnapshot.docs) {
        final uid = doc.id;
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim().toLowerCase();
        final displayName = (data['name'] ?? '').toString();
        final phone = (data['phone'] ?? '').toString().trim();

        officeDriverUids.add(uid);
        officeDriverSuspendedMap[uid] = data['isSuspended'] == true;

        if (displayName.isNotEmpty) {
          officeDriverUidToNameMap[uid] = displayName;
        }
        if (name.isNotEmpty) {
          officeDriverNameToUid[name] = uid;
        }
        if (phone.isNotEmpty) {
          officeDriverPhoneToUid[phone] = uid;
        }
      }

      // 2. جلب بيانات المناديب المستقلين من courier_requests
      final couriersSnapshot = await _firestore.collection('courier_requests').get();
      final Map<String, String> courierNames = {};
      final Map<String, String> courierDocIdToUidMap = {};
      final Map<String, bool> independentCourierSuspendedMap = {};
      final Set<String> independentCourierUids = {};
      final Map<String, String> independentCourierNameToUid = {};
      final Map<String, String> independentCourierPhoneToUid = {};
      for (var doc in couriersSnapshot.docs) {
        final d = doc.data();
        final id = doc.id;
        final name = (d['name'] ?? d['fullName'] ?? d['courierName'] ?? d['nameAr'] ?? '').toString();
        final uid = (d['courierUid'] ?? d['uid'] ?? d['userId'] ?? id).toString();
        final phone = (d['phone'] ?? '').toString().trim();

        if (name.isNotEmpty) {
          courierNames[uid] = name;
          courierNames[id] = name;
        }
        if (uid.isNotEmpty) {
          courierDocIdToUidMap[id] = uid;
          courierDocIdToUidMap[uid] = uid;
        }
        if (uid.isNotEmpty && !officeDriverUids.contains(uid)) {
          independentCourierUids.add(uid);
          independentCourierSuspendedMap[uid] = d['isSuspended'] == true;
          if (name.isNotEmpty) {
            independentCourierNameToUid[name.trim().toLowerCase()] = uid;
          }
          if (phone.isNotEmpty) {
            independentCourierPhoneToUid[phone] = uid;
          }
        }
      }

      final now = DateTime.now();
      Query query = _firestore.collection('orders');

      if (_selectedFilter == 'today') {
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        query = query
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('createdAt', isLessThan: Timestamp.fromDate(end));
      } else if (_selectedFilter == '7days') {
        final start = now.subtract(const Duration(days: 7));
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
      } else if (_selectedFilter == '30days') {
        final start = now.subtract(const Duration(days: 30));
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
      }

      final snapshot = await query.get();

      final Map<String, Map<String, dynamic>> storeSales = {};
      final Map<String, Map<String, dynamic>> driverActivity = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (_isCompletedOrder(data)) {
          // المتجر
          final storeId = (data['storeId'] ?? data['marketId'] ?? '').toString();
          final storeName = (data['storeName'] ?? 'متجر غير معروف').toString();
          final totalAmount = _toD(data['totalAmount']);

          if (storeId.isNotEmpty) {
            if (!storeSales.containsKey(storeId)) {
              storeSales[storeId] = {
                'id': storeId,
                'name': storeName,
                'sales': 0.0,
                'count': 0,
                'orders': [],
              };
            }
            storeSales[storeId]!['sales'] = (storeSales[storeId]!['sales'] as double) + totalAmount;
            storeSales[storeId]!['count'] = (storeSales[storeId]!['count'] as int) + 1;
            (storeSales[storeId]!['orders'] as List).add({
              'orderId': (data['orderId'] ?? doc.id).toString(),
              'totalAmount': totalAmount,
              'createdAt': data['createdAt'] ?? data['placedAt'],
            });
          }

          // المندوب
          final deliveryRequest = (data['deliveryRequest'] as Map<String, dynamic>?) ?? const {};
          final delivery = (data['delivery'] as Map<String, dynamic>?) ?? const {};
          final currentActor = (delivery['currentActor'] as Map<String, dynamic>?) ?? const {};

          final rawDriverId = (data['assignedCourierId'] ??
              deliveryRequest['courierId'] ??
              deliveryRequest['driverId'] ??
              deliveryRequest['assignedDriverId'] ??
              currentActor['id'])?.toString() ?? '';

          var driverName = (deliveryRequest['assignedDriverName'] ??
              deliveryRequest['driverName'] ??
              deliveryRequest['driver_name'] ??
              currentActor['name'])?.toString() ?? '';

          final rawPhone = (deliveryRequest['driverPhone'] ??
              deliveryRequest['driver_phone'] ??
              currentActor['phone'])?.toString() ?? '';

          // حل معرف المندوب (Auth UID) بطريقة مرنة
          String driverId = '';

          if (rawDriverId.isNotEmpty) {
            if (officeDriverUids.contains(rawDriverId)) {
              driverId = rawDriverId;
            } else if (independentCourierUids.contains(rawDriverId)) {
              driverId = rawDriverId;
            } else if (courierDocIdToUidMap.containsKey(rawDriverId)) {
              final resolvedUid = courierDocIdToUidMap[rawDriverId]!;
              if (officeDriverUids.contains(resolvedUid) ||
                  independentCourierUids.contains(resolvedUid)) {
                driverId = resolvedUid;
              }
            } else if (officeDriverNameToUid.containsKey(rawDriverId.trim().toLowerCase())) {
              driverId = officeDriverNameToUid[rawDriverId.trim().toLowerCase()]!;
            } else if (independentCourierNameToUid.containsKey(rawDriverId.trim().toLowerCase())) {
              driverId = independentCourierNameToUid[rawDriverId.trim().toLowerCase()]!;
            }
          }

          if (driverId.isEmpty && driverName.isNotEmpty) {
            final nameKey = driverName.trim().toLowerCase();
            driverId = officeDriverNameToUid[nameKey] ??
                independentCourierNameToUid[nameKey] ??
                '';
          }

          if (driverId.isEmpty && rawPhone.isNotEmpty) {
            final phoneKey = rawPhone.trim();
            driverId = officeDriverPhoneToUid[phoneKey] ??
                independentCourierPhoneToUid[phoneKey] ??
                '';
          }

          // إذا لم ننجح في حله، نلجأ للمعرف الأصلي المتوفر
          if (driverId.isEmpty) {
            driverId = rawDriverId;
          }

          // جلب اسم المندوب الحقيقي من السجل المناسب
          if (driverId.isNotEmpty && officeDriverUidToNameMap.containsKey(driverId)) {
            driverName = officeDriverUidToNameMap[driverId]!;
          } else if (driverName.isEmpty && driverId.isNotEmpty) {
            driverName = courierNames[driverId] ?? 'مندوب غير معروف';
          }
          if (driverName.isEmpty) {
            driverName = 'مندوب غير معروف';
          }

          if (driverId.isNotEmpty) {
            if (!driverActivity.containsKey(driverId)) {
              final isOfficeDriver = officeDriverUids.contains(driverId);
              final isIndependentCourier = independentCourierUids.contains(driverId);
              driverActivity[driverId] = {
                'id': driverId,
                'name': driverName,
                'count': 0,
                'driverType': isOfficeDriver
                    ? 'office'
                    : (isIndependentCourier ? 'independent' : 'unknown'),
                'managedCollection': isOfficeDriver
                    ? 'users'
                    : (isIndependentCourier ? 'courier_requests' : null),
                'managedDocId': isOfficeDriver || isIndependentCourier ? driverId : null,
                'isSuspended': isOfficeDriver
                    ? (officeDriverSuspendedMap[driverId] ?? false)
                    : (isIndependentCourier
                        ? (independentCourierSuspendedMap[driverId] ?? false)
                        : false),
                'orders': [],
              };
            }
            driverActivity[driverId]!['count'] = (driverActivity[driverId]!['count'] as int) + 1;
            (driverActivity[driverId]!['orders'] as List).add({
              'orderId': (data['orderId'] ?? doc.id).toString(),
              'totalAmount': totalAmount,
              'createdAt': data['createdAt'] ?? data['placedAt'],
            });
          }
        }
      }

      // فرز فواتير المتجر حسب التاريخ تنازلياً (الأحدث أولاً)
      for (var store in storeSales.values) {
        final List orders = store['orders'];
        orders.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
      }

      // فرز فواتير المندوب حسب التاريخ تنازلياً (الأحدث أولاً)
      for (var driver in driverActivity.values) {
        final List orders = driver['orders'];
        orders.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
      }

      _allStores = storeSales.values.toList()
        ..sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));

      _allDrivers = driverActivity.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      _filterLists();
    } catch (e) {
      print('خطأ في جلب التحليلات: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    _filterLists();
  }

  void _filterLists() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (_tabController.index == 0) {
        if (query.isEmpty) {
          _filteredStores = List.from(_allStores);
        } else {
          _filteredStores = _allStores.where((store) {
            final name = (store['name'] as String).toLowerCase();
            return name.contains(query);
          }).toList();
        }
      } else {
        if (query.isEmpty) {
          _filteredDrivers = List.from(_allDrivers);
        } else {
          _filteredDrivers = _allDrivers.where((driver) {
            final name = (driver['name'] as String).toLowerCase();
            return name.contains(query);
          }).toList();
        }
      }
    });
  }

  Future<void> _toggleDriverSuspension(
    String docId,
    String collection,
    bool currentlySuspended,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentlySuspended ? 'إلغاء عقوبة الإيقاف' : 'إيقاف المندوب (عقاب)'),
        content: Text(currentlySuspended
            ? 'هل أنت متأكد من تفعيل هذا المندوب ليتمكن من استقبال طلبات التوصيل مجدداً؟'
            : 'هل أنت متأكد من إيقاف هذا المندوب؟ سيتم وضعه في وضع عدم الاتصال فوراً ولن يتمكن من استقبال أي طلبات.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlySuspended ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(currentlySuspended ? 'تفعيل وتأكيد' : 'إيقاف وعقاب'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final shouldSuspend = !currentlySuspended;

        final docRef = _firestore.collection(collection).doc(docId);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          throw Exception('مستند المندوب غير موجود في $collection');
        }

        if (collection == 'users') {
          await docRef.update({
            'isSuspended': shouldSuspend,
            if (shouldSuspend) 'status': false,
          });
        } else if (collection == 'courier_requests') {
          await docRef.update({
            'isSuspended': shouldSuspend,
            if (shouldSuspend) 'isOnline': false,
          });
        } else {
          throw Exception('مجموعة غير مدعومة: $collection');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shouldSuspend ? 'تم إيقاف المندوب وحظر استقباله للطلبات' : 'تم إلغاء العقوبة وتفعيل المندوب بنجاح'),
            backgroundColor: shouldSuspend ? Colors.red : Colors.green,
          ),
        );
        await _loadData();
      } catch (e) {
        print('خطأ في تغيير حالة المندوب: $e (المجموعة: $collection، المعرف: $docId)');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تعديل حالة المندوب ($docId):\n$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10), // زيادة المدة ليتمكن المستخدم من قراءتها
          ),
        );
        setState(() => _isLoading = false);
      }
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
      appBar: AppBar(
        title: const Text(
          'تحليلات المبيعات والنشاط',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.store_rounded), text: 'المبيعات حسب المتجر'),
            Tab(icon: Icon(Icons.motorcycle_rounded), text: 'نشاط المناديب'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.mainColor.withOpacity(0.02),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildFilterAndSearchRow(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStoresTab(),
                        _buildDriversTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterAndSearchRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // فلتر المدة الزمنية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المدة الزمنية:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('today', 'اليوم'),
                      const SizedBox(width: 8),
                      _buildFilterChip('7days', '7 أيام'),
                      const SizedBox(width: 8),
                      _buildFilterChip('30days', '30 يوماً'),
                      const SizedBox(width: 8),
                      _buildFilterChip('all', 'الكل'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _tabController.index == 0
                  ? 'البحث عن متجر...'
                  : 'البحث عن مندوب...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.mainColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.mainColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
            _currentPageMap.clear();
          });
          _loadData();
        }
      },
    );
  }

  Widget _buildStoresTab() {
    if (_filteredStores.isEmpty) {
      return Center(
        child: Text(
          'لا توجد بيانات متاجر مطابقة',
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      );
    }

    final maxSales = _allStores.isNotEmpty
        ? (_allStores.first['sales'] as double)
        : 1.0;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStores.length,
      itemBuilder: (context, index) {
        final store = _filteredStores[index];
        final id = store['id'] as String;
        final rank = _allStores.indexWhere((s) => s['id'] == id) + 1;
        final name = store['name'] as String;
        final sales = store['sales'] as double;
        final count = store['count'] as int;
        final ratio = maxSales > 0 ? (sales / maxSales) : 0.0;
        final isExpanded = _expandedItems[id] == true;
        final ordersList = (store['orders'] as List? ?? []).cast<Map<String, dynamic>>();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.04),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _expandedItems[id] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildRankBadge(rank),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isExpanded ? 'اضغط لإخفاء الطلبات' : 'اضغط لعرض الطلبات التفصيلية',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${sales.toStringAsFixed(1)} ج.م',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.mainColor,
                            ),
                          ),
                          Text(
                            '$count طلب مكتمل',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rank == 1 ? Colors.amber : AppColors.mainColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    const Text(
                      'الطلبات المكتملة:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    if (ordersList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('لا توجد طلبات مسجلة لهذه الفترة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'إجمالي الفواتير: ${ordersList.length}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                          Text(
                            'الصفحة ${_currentPageMap[id] ?? 1} من ${((ordersList.length) / _pageSize).ceil()}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final int currentPage = _currentPageMap[id] ?? 1;
                          final int totalOrders = ordersList.length;
                          final int startIndex = (currentPage - 1) * _pageSize;
                          final int endIndex = startIndex + _pageSize;
                          final paginatedOrders = ordersList.sublist(
                            startIndex,
                            endIndex > totalOrders ? totalOrders : endIndex,
                          );

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: paginatedOrders.length,
                            itemBuilder: (context, idx) {
                              final o = paginatedOrders[idx];
                              final orderId = o['orderId'] as String;
                              final amount = o['totalAmount'] as double;
                              final dateStr = _formatDate(o['createdAt']);

                              return InkWell(
                                onTap: () {
                                  context.push('/admin/order-lookup?orderId=$orderId');
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[200]!, width: 0.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.receipt_long_rounded, color: AppColors.mainColor, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'رقم الطلب: #$orderId',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF2C3E50)),
                                            ),
                                            Text(
                                              dateStr,
                                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${amount.toStringAsFixed(1)} ج.م',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios_rounded, color: AppColors.mainColor, size: 12),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final int currentPage = _currentPageMap[id] ?? 1;
                          final int totalPages = (ordersList.length / _pageSize).ceil();
                          if (totalPages <= 1) return const SizedBox.shrink();

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: currentPage > 1 ? () {
                                  setState(() {
                                    _currentPageMap[id] = currentPage - 1;
                                  });
                                } : null,
                                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: List.generate(totalPages, (pIdx) {
                                  final p = pIdx + 1;
                                  final isCurrent = currentPage == p;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentPageMap[id] = p;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isCurrent ? AppColors.mainColor : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isCurrent ? AppColors.mainColor : Colors.grey[300]!,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        p.toString(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: currentPage < totalPages ? () {
                                  setState(() {
                                    _currentPageMap[id] = currentPage + 1;
                                  });
                                } : null,
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          );
                        }
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriversTab() {
    if (_filteredDrivers.isEmpty) {
      return Center(
        child: Text(
          'لا توجد بيانات مناديب مطابقة',
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDrivers.length,
      itemBuilder: (context, index) {
        final driver = _filteredDrivers[index];
        final id = driver['id'] as String;
        final rank = _allDrivers.indexWhere((d) => d['id'] == id) + 1;
        final name = driver['name'] as String;
        final count = driver['count'] as int;
        final isSuspended = driver['isSuspended'] == true;
        final driverType = driver['driverType'] as String? ?? 'unknown';
        final managedCollection = driver['managedCollection'] as String?;
        final managedDocId = driver['managedDocId'] as String?;
        final canManageDriver =
            managedCollection != null && managedDocId != null && managedDocId.isNotEmpty;
        final isExpanded = _expandedItems[id] == true;
        final ordersList = (driver['orders'] as List? ?? []).cast<Map<String, dynamic>>();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.04),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _expandedItems[id] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildRankBadge(rank),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (driverType == 'office') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'مكتب شحن',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else if (driverType == 'independent') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'مستقل',
                                      style: TextStyle(
                                        color: Colors.purple[700],
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isSuspended) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'موقوف عقاباً',
                                      style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isExpanded ? 'اضغط لإخفاء الخيارات والطلبات' : 'اضغط لعرض الطلبات والتحكم',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSuspended ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count توصيلة',
                          style: TextStyle(
                            color: isSuspended ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // الإدارة الإيقافية للمندوب
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجراءات الإدارية:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        ElevatedButton.icon(
                          onPressed: canManageDriver
                              ? () => _toggleDriverSuspension(
                                    managedDocId,
                                    managedCollection,
                                    isSuspended,
                                  )
                              : null,
                          icon: Icon(
                            isSuspended ? Icons.check_circle_outline : Icons.gavel_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            canManageDriver
                                ? (isSuspended ? 'إلغاء العقوبة وتفعيل المندوب' : 'إيقاف المندوب كعقاب')
                                : 'تعذر إدارة حالة هذا المندوب',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSuspended ? Colors.green : Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    const Text(
                      'طلبات التوصيل المكتملة:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    if (ordersList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('لا توجد توصيلات مسجلة لهذه الفترة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'إجمالي الفواتير: ${ordersList.length}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                          Text(
                            'الصفحة ${_currentPageMap[id] ?? 1} من ${((ordersList.length) / _pageSize).ceil()}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final int currentPage = _currentPageMap[id] ?? 1;
                          final int totalOrders = ordersList.length;
                          final int startIndex = (currentPage - 1) * _pageSize;
                          final int endIndex = startIndex + _pageSize;
                          final paginatedOrders = ordersList.sublist(
                            startIndex,
                            endIndex > totalOrders ? totalOrders : endIndex,
                          );

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: paginatedOrders.length,
                            itemBuilder: (context, idx) {
                              final o = paginatedOrders[idx];
                              final orderId = o['orderId'] as String;
                              final amount = o['totalAmount'] as double;
                              final dateStr = _formatDate(o['createdAt']);

                              return InkWell(
                                onTap: () {
                                  context.push('/admin/invoice-lookup?number=$orderId');
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[200]!, width: 0.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.receipt_long_rounded, color: Colors.green, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'رقم الطلب: #$orderId',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF2C3E50)),
                                            ),
                                            Text(
                                              dateStr,
                                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${amount.toStringAsFixed(1)} ج.م',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.green, size: 12),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final int currentPage = _currentPageMap[id] ?? 1;
                          final int totalPages = (ordersList.length / _pageSize).ceil();
                          if (totalPages <= 1) return const SizedBox.shrink();

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: currentPage > 1 ? () {
                                  setState(() {
                                    _currentPageMap[id] = currentPage - 1;
                                  });
                                } : null,
                                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: List.generate(totalPages, (pIdx) {
                                  final p = pIdx + 1;
                                  final isCurrent = currentPage == p;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentPageMap[id] = p;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isCurrent ? AppColors.mainColor : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isCurrent ? AppColors.mainColor : Colors.grey[300]!,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        p.toString(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: currentPage < totalPages ? () {
                                  setState(() {
                                    _currentPageMap[id] = currentPage + 1;
                                  });
                                } : null,
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          );
                        }
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    Color textColor = Colors.white;
    switch (rank) {
      case 1:
        color = Colors.amber;
        break;
      case 2:
        color = const Color(0xFFC0C0C0);
        break;
      case 3:
        color = const Color(0xFFCD7F32);
        break;
      default:
        color = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        rank.toString(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
