import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewmodels/promotional_popup_viewmodel.dart';
import '../../notifications/widgets/audience_selector.dart';

/// صفحة إنشاء/تعديل إعلان منبثق
class CreateEditPopupPage extends StatefulWidget {
  final String? popupId;

  const CreateEditPopupPage({super.key, this.popupId});

  @override
  State<CreateEditPopupPage> createState() => _CreateEditPopupPageState();
}

class _CreateEditPopupPageState extends State<CreateEditPopupPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');
  final _maxImpressionsController = TextEditingController(text: '0');
  bool _isEdit = false;
  String? _selectedEntityName;

  Future<void> _loadEntityName(String type, String id) async {
    if (id.isEmpty) return;
    try {
      final collection = type == 'open_store' ? 'markets' : 'craftsmen';
      final doc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _selectedEntityName = data?['name'] ?? 'بدون اسم';
        });
      }
    } catch (e) {
      debugPrint('Error loading entity name: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _isEdit = widget.popupId != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<PromotionalPopupViewModel>();
      if (_isEdit) {
        vm.loadPopup(widget.popupId!).then((_) {
          if (!mounted) return;
          _titleController.text = vm.title ?? '';
          _descController.text = vm.description ?? '';
          _priorityController.text = vm.priority.toString();
          _maxImpressionsController.text = vm.maxImpressions.toString();
          if (vm.hasCTA && (vm.ctaType == 'open_store' || vm.ctaType == 'open_craftsman')) {
            _loadEntityName(vm.ctaType, vm.ctaValue);
          }
        });
      } else {
        vm.resetForm();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priorityController.dispose();
    _maxImpressionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'تعديل الإعلان المنبثق' : 'إنشاء إعلان منبثق',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<PromotionalPopupViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && _isEdit) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة الإعلان
                _buildImageSection(vm),
                const SizedBox(height: 20),

                // العنوان والوصف
                TextFormField(
                  controller: _titleController,
                  onChanged: vm.setTitle,
                  decoration: InputDecoration(
                    labelText: 'العنوان (اختياري)',
                    prefixIcon: const Icon(Icons.title_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  onChanged: vm.setDescription,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 30),
                      child: Icon(Icons.description_rounded),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // الفئة المستهدفة
                AudienceSelector(
                  selectedAudience: vm.targetAudience,
                  onChanged: vm.setTargetAudience,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // التواريخ
                const Text(
                  'فترة العرض',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDatePicker('تاريخ البداية', vm.startDate, (d) => vm.setStartDate(d))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDatePicker('تاريخ الانتهاء', vm.endDate, (d) => vm.setEndDate(d))),
                  ],
                ),
                const SizedBox(height: 20),

                // الأولوية والحد الأقصى
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priorityController,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => vm.setPriority(int.tryParse(v) ?? 0),
                        decoration: InputDecoration(
                          labelText: 'الأولوية',
                          helperText: 'الأعلى يظهر أولاً',
                          prefixIcon: const Icon(Icons.sort_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxImpressionsController,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => vm.setMaxImpressions(int.tryParse(v) ?? 0),
                        decoration: InputDecoration(
                          labelText: 'حد الظهور',
                          helperText: '0 = بلا حد',
                          prefixIcon: const Icon(Icons.visibility_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildCTASection(vm),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Switches
                SwitchListTile(
                  title: const Text('قابل للإغلاق', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('هل يمكن للمستخدم إغلاقه', style: TextStyle(fontSize: 12)),
                  value: vm.isDismissible,
                  onChanged: vm.setIsDismissible,
                  activeColor: const Color(0xFFE91E63),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('مفعّل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('يظهر فقط إذا كان مفعّلاً وضمن فترة العرض', style: TextStyle(fontSize: 12)),
                  value: vm.isActive,
                  onChanged: vm.setIsActive,
                  activeColor: const Color(0xFFE91E63),
                  contentPadding: EdgeInsets.zero,
                ),

                // خطأ
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(vm.errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 24),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: vm.isLoading ? null : () => _save(vm),
                    icon: vm.isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      vm.isLoading ? 'جاري الحفظ...' : (_isEdit ? 'حفظ التعديلات' : 'إنشاء الإعلان'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection(PromotionalPopupViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صورة الإعلان *',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 12),
        if (vm.imageFile != null || (vm.imageUrl != null && vm.imageUrl!.isNotEmpty))
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: vm.imageFile != null
                    ? Image.file(vm.imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(vm.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8, left: 8,
                child: InkWell(
                  onTap: () { vm.setImageFile(null); vm.setImageUrl(null); },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: () => _pickImage(vm),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded, size: 40, color: Color(0xFFE91E63)),
                  SizedBox(height: 8),
                  Text('اضغط لرفع صورة الإعلان', style: TextStyle(color: Color(0xFFE91E63), fontSize: 13)),
                  SizedBox(height: 4),
                  Text('إجبارية', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('ar'),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFFE91E63)),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              DateFormat('yyyy/MM/dd').format(date),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(PromotionalPopupViewModel vm) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
    if (picked != null) vm.setImageFile(File(picked.path));
  }

  Future<void> _save(PromotionalPopupViewModel vm) async {
    bool success;
    if (_isEdit) {
      success = await vm.updatePopup(widget.popupId!);
    } else {
      success = await vm.savePopup();
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.successMessage ?? 'تم بنجاح'),
          backgroundColor: const Color(0xFF2ECC71),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.go('/admin/promotional-popups');
    }
  }

  Widget _buildCTASection(PromotionalPopupViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text(
            'توجيه عند النقر (CTA)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          subtitle: const Text(
            'توجيه المستخدم لصفحة، متجر، حرفي، أو رابط خارجي عند النقر على صورة الإعلان',
            style: TextStyle(fontSize: 12),
          ),
          value: vm.hasCTA,
          onChanged: vm.setHasCTA,
          activeColor: const Color(0xFFE91E63),
          contentPadding: EdgeInsets.zero,
        ),
        if (vm.hasCTA) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: vm.ctaType,
            decoration: InputDecoration(
              labelText: 'نوع التوجيه',
              prefixIcon: const Icon(Icons.touch_app_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: const [
              DropdownMenuItem(value: 'open_page', child: Text('فتح صفحة معينة')),
              DropdownMenuItem(value: 'open_store', child: Text('فتح متجر محدد')),
              DropdownMenuItem(value: 'open_craftsman', child: Text('فتح حساب حرفي')),
              DropdownMenuItem(value: 'external_link', child: Text('رابط خارجي')),
            ],
            onChanged: (val) {
              if (val != null) {
                vm.setCTAType(val);
                vm.setCTAValue('');
                setState(() {
                  _selectedEntityName = null;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          _buildCTAValueInput(vm),
        ],
      ],
    );
  }

  Widget _buildCTAValueInput(PromotionalPopupViewModel vm) {
    if (vm.ctaType == 'open_page') {
      final pages = [
        {'value': '/HomePage', 'label': 'الرئيسية'},
        {'value': '/inbox', 'label': 'مركز الرسائل / الصندوق الوارد'},
        {'value': '/support', 'label': 'الدعم الفني / مركز المساعدة'},
        {'value': '/CartPage', 'label': 'سلة المشتريات'},
        {'value': '/AccountPage', 'label': 'حسابي / الملف الشخصي'},
        {'value': '/favourite-markets', 'label': 'المتاجر المفضلة'},
        {'value': '/craftsmen', 'label': 'قسم الحرفيين'},
      ];

      final initialVal = pages.any((p) => p['value'] == vm.ctaValue)
          ? vm.ctaValue
          : '';

      return DropdownButtonFormField<String>(
        value: initialVal.isNotEmpty ? initialVal : null,
        decoration: InputDecoration(
          labelText: 'اختر الصفحة',
          prefixIcon: const Icon(Icons.layers_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: pages.map((p) {
          return DropdownMenuItem<String>(
            value: p['value'],
            child: Text(p['label']!),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            vm.setCTAValue(val);
          }
        },
      );
    } else if (vm.ctaType == 'open_store') {
      return InkWell(
        onTap: () {
          _showSearchableSelector(
            title: 'اختر متجراً من القائمة',
            collectionName: 'markets',
            labelField: 'name',
            onSelected: (doc) {
              vm.setCTAValue(doc.id);
              setState(() {
                _selectedEntityName = (doc.data() as Map<String, dynamic>)['name'] ?? 'بدون اسم';
              });
            },
          );
        },
        child: IgnorePointer(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'المتجر المختار',
              hintText: 'اضغط لاختيار متجر...',
              prefixIcon: const Icon(Icons.store_rounded),
              suffixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            controller: TextEditingController(
              text: _selectedEntityName ?? (vm.ctaValue.isNotEmpty ? 'معرّف: ${vm.ctaValue}' : ''),
            ),
          ),
        ),
      );
    } else if (vm.ctaType == 'open_craftsman') {
      return InkWell(
        onTap: () {
          _showSearchableSelector(
            title: 'اختر حرفياً من القائمة',
            collectionName: 'craftsmen',
            labelField: 'name',
            onSelected: (doc) {
              vm.setCTAValue(doc.id);
              setState(() {
                _selectedEntityName = (doc.data() as Map<String, dynamic>)['name'] ?? 'بدون اسم';
              });
            },
          );
        },
        child: IgnorePointer(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'الحرفي المختار',
              hintText: 'اضغط لاختيار حرفي...',
              prefixIcon: const Icon(Icons.handyman_rounded),
              suffixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            controller: TextEditingController(
              text: _selectedEntityName ?? (vm.ctaValue.isNotEmpty ? 'معرّف: ${vm.ctaValue}' : ''),
            ),
          ),
        ),
      );
    } else {
      return TextFormField(
        initialValue: vm.ctaValue,
        keyboardType: TextInputType.url,
        onChanged: vm.setCTAValue,
        decoration: InputDecoration(
          labelText: 'الرابط الخارجي (URL)',
          hintText: 'https://example.com',
          prefixIcon: const Icon(Icons.link_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      );
    }
  }

  void _showSearchableSelector({
    required String title,
    required String collectionName,
    required String labelField,
    required ValueChanged<DocumentSnapshot> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setStateSheet(() {
                        searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('لا توجد بيانات'));
                        }

                        final docs = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data[labelField] ?? '').toString().toLowerCase();
                          return name.contains(searchQuery);
                        }).toList();

                        if (docs.isEmpty) {
                          return const Center(child: Text('لا توجد نتائج مطابقة'));
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data[labelField] ?? 'بدون اسم';

                            return ListTile(
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('ID: ${doc.id}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              onTap: () {
                                onSelected(doc);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
