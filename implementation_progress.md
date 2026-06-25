# 📋 نظام الإشعارات والإعلانات — سجل التتبع

> **هام للنموذج التالي**: اقرأ هذا الملف أولاً لمعرفة أين وصلنا في التنفيذ.

## 🏗️ المراحل والتقدم

### المرحلة 1: تطبيق الأدمن — Models + Services + ViewModels ✅
- [x] جميع ملفات `lib/notifications/` و `lib/promotional_popups/`

### المرحلة 2: تطبيق الأدمن — الصفحات والويدجيتات ✅
- [x] جميع الصفحات والويدجيتات

### المرحلة 3: الإعلانات المنبثقة (Promotional Popups) — الأدمن ✅
- [x] كامل

### المرحلة 4: الربط والتوجيه — الأدmin ✅
- [x] `admin_routes.dart`, `dashboard_page.dart`, `main.dart`
- [x] زر إرسال إشعار في `store_commission_page.dart` (تفاصيل المتجر)
- [x] زر إرسال إشعار في `courier_request_detail_page.dart`
- [x] زر إرسال إشعار في `report_detail_page.dart`
- [ ] `office_detail_page.dart` — الصفحة غير موجودة بعد (مؤجل)

### المرحلة 5: تطبيق المستخدمين (temp_bazar) ✅
- [x] `lib/notifications/models/inbox_message_model.dart`
- [x] `lib/notifications/models/promotional_popup_model.dart`
- [x] `lib/notifications/services/inbox_service.dart`
- [x] `lib/notifications/services/popup_display_service.dart`
- [x] `lib/notifications/viewmodels/inbox_viewmodel.dart`
- [x] `lib/notifications/pages/inbox_page.dart`
- [x] `lib/notifications/pages/message_detail_page.dart`
- [x] `lib/notifications/widgets/inbox_badge.dart`
- [x] `lib/notifications/widgets/promotional_popup_dialog.dart`
- [x] `lib/notifications/widgets/notification_host.dart`
- [x] تعديل `lib/services/fcm_service.dart`
- [x] تعديل `lib/services/fcm_background_handler.dart`
- [x] تعديل `lib/services/order_notifications/local_notification_service.dart`
- [x] تعديل `lib/main.dart`, `router`, `layouts`, `account_page`

### المرحلة 6: تطبيق المناديب (bazaarsuezdriver) ✅
- [x] `lib/features/notifications/` (Riverpod)
- [x] تعديل `lib/services/notification_service.dart`
- [x] مسارات `/inbox` في `app_router.dart`
- [x] رابط في `profile_tab_view.dart`

### المرحلة 7: Cloud Functions ✅
- [x] موجودة ومُجمّعة في `D:\project\bazarsuez\bazar_suez\functions\`
  - `sendAnnouncement.ts` → `lib/notifications/sendAnnouncement.js`
  - `sendDirectNotification.ts` → `lib/notifications/sendDirectNotification.js`
  - `scheduledSender.ts` → `lib/notifications/scheduledSender.js`

---

## 🔄 الحالة الحالية

**آخر تحديث**: إصلاح مشكلة «جاري الإرسال» + إزالة القوالب من الواجهة

### إصلاحات (يونيو 2025)
- **سبب التعليق**: الأدمن كان يضبط `status: sending` قبل Cloud Function، والـ Function كانت تتخطى الإرسال → الإعلان يبقى «جاري الإرسال» للأبد
- **الحل**: لا تحديث `sending` من الأدمن؛ `in_app_only` يُنشر مباشرة في Firestore بدون CF؛ زر **إعادة الإرسال** في تفاصيل الإعلان
- **القوالب**: أُزيلت من لوحة التحكم، صفحة الإنشاء، والإرسال الفردي (الملفات باقية في المشروع لكن غير مربوطة)

**الخطوة التالية**: اختبار يدوي — جرّب «رسالة داخلية فقط» أولاً؛ ثم انشر Cloud Functions للإشعار الفوري

```bash
cd D:\project\bazarsuez\bazar_suez\functions
firebase deploy --only functions:sendAnnouncement,functions:sendDirectNotification
```

---

## 📌 ملاحظات هامة

1. **Cloud Functions**: المجلد في `bazar_suez/functions/` وليس `suez_admin/`
2. **منطقة Functions**: `europe-west1`
3. **مركز الرسائل**: استعلام مركزي من `announcements/` + قراءة محلية عبر SharedPreferences
4. **FCM payload للإعلانات**: `{ type: 'announcement', announcementId: '...' }`

---

## 📂 مسارات المشاريع
- **الأدمن**: `d:\project\suezadmin\suez_admin`
- **المستخدمين**: `d:\project\bazarsuez\bazar_suez\temp_bazar`
- **المناديب**: `d:\project\bazaarsuezdriver\bazaarsuezdriver`
- **Cloud Functions**: `d:\project\bazarsuez\bazar_suez\functions`
