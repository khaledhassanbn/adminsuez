import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/support_conversation.dart';
import '../services/admin_support_service.dart';
import '../services/support_image_service.dart';

class AdminSupportViewModel extends ChangeNotifier {
  final AdminSupportService _service = AdminSupportService();
  final SupportImageService _imageService = SupportImageService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // فلاتر
  String? _statusFilter = 'all';
  String? _userTypeFilter = 'all';
  String? _issueTypeFilter = 'all';
  String? _priorityFilter = 'all';
  String? _sourceFilter = 'all';
  String? _searchQuery = '';

  bool _isUploadingImage = false;
  String? _errorMessage;

  // إشعارات وتنبيهات حية
  final Set<String> _seenConversationIds = {};
  bool _isFirstLoad = true;
  String? _newTicketAlertName;

  String? get statusFilter => _statusFilter;
  String? get userTypeFilter => _userTypeFilter;
  String? get issueTypeFilter => _issueTypeFilter;
  String? get priorityFilter => _priorityFilter;
  String? get sourceFilter => _sourceFilter;
  String? get searchQuery => _searchQuery;

  bool get isUploadingImage => _isUploadingImage;
  String? get errorMessage => _errorMessage;
  String? get newTicketAlertName => _newTicketAlertName;

  AdminSupportViewModel() {
    _startNewTicketListener();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// الاستماع لوصول تذاكر دعم جديدة
  void _startNewTicketListener() {
    FirebaseFirestore.instance
        .collection('support_conversations')
        .snapshots()
        .listen((snapshot) {
      if (_isFirstLoad) {
        // في أول تحميل، نحفظ فقط المعرفات الموجودة مسبقاً دون إرسال تنبيهات
        for (final doc in snapshot.docs) {
          _seenConversationIds.add(doc.id);
        }
        _isFirstLoad = false;
        return;
      }

      // البحث عن تذاكر جديدة
      for (final doc in snapshot.docs) {
        if (!_seenConversationIds.contains(doc.id)) {
          _seenConversationIds.add(doc.id);
          
          // تذكرة جديدة!
          final data = doc.data();
          final name = data['userName']?.toString() ?? 'مستخدم';
          
          _triggerNewTicketAlert(name);
        }
      }
    });
  }

  void _triggerNewTicketAlert(String userName) async {
    _newTicketAlertName = userName;
    notifyListeners();

    // تشغيل صوت التنبيه
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print('Error playing notification sound: $e');
    }

    // تصفير التنبيه بعد 5 ثوانٍ
    Future.delayed(const Duration(seconds: 5), () {
      if (_newTicketAlertName == userName) {
        _newTicketAlertName = null;
        notifyListeners();
      }
    });
  }

  void clearAlert() {
    _newTicketAlertName = null;
    notifyListeners();
  }

  void setStatusFilter(String? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setUserTypeFilter(String? value) {
    _userTypeFilter = value;
    notifyListeners();
  }

  void setIssueTypeFilter(String? value) {
    _issueTypeFilter = value;
    notifyListeners();
  }

  void setPriorityFilter(String? value) {
    _priorityFilter = value;
    notifyListeners();
  }

  void setSourceFilter(String? value) {
    _sourceFilter = value;
    notifyListeners();
  }

  void setSearchQuery(String? value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = 'all';
    _userTypeFilter = 'all';
    _issueTypeFilter = 'all';
    _priorityFilter = 'all';
    _sourceFilter = 'all';
    _searchQuery = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// الحصول على قائمة المحادثات المفلترة
  Stream<List<SupportConversation>> get filteredConversations {
    return _service.getAllConversations(
      statusFilter: _statusFilter,
      userTypeFilter: _userTypeFilter,
      issueTypeFilter: _issueTypeFilter,
      priorityFilter: _priorityFilter,
      sourceFilter: _sourceFilter,
    );
  }

  /// تغيير حالة المحادثة
  Future<void> updateStatus(String conversationId, ConversationStatus newStatus) async {
    try {
      _errorMessage = null;
      await _service.updateStatus(conversationId, newStatus);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// تغيير الأولوية
  Future<void> updatePriority(String conversationId, ConversationPriority newPriority) async {
    try {
      _errorMessage = null;
      await _service.updatePriority(conversationId, newPriority);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// إرسال رد نصي
  Future<void> sendReply({
    required String conversationId,
    String? text,
  }) async {
    try {
      _errorMessage = null;
      await _service.sendAdminReply(
        conversationId: conversationId,
        text: text,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// التقاط صورة ورفعها وإرسالها
  Future<void> pickAndSendImage({
    required String conversationId,
    bool fromCamera = false,
  }) async {
    try {
      _errorMessage = null;
      final file = fromCamera 
          ? await _imageService.takePhoto() 
          : await _imageService.pickImage();
          
      if (file == null) return; // تم الإلغاء

      _isUploadingImage = true;
      notifyListeners();

      final imageUrl = await _imageService.uploadImage(file, conversationId);
      await _service.sendAdminReply(
        conversationId: conversationId,
        text: '',
        imageUrl: imageUrl,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }
}
