import 'package:flutter/material.dart';

/// Extension لحماية setState من الاستدعاء على widget تم التخلص منه
extension SafeStateExtension on State {
  /// استدعاء setState آمن - يتحقق من mounted وحالة العنصر قبل الاستدعاء
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      try {
        // فحص إضافي للتأكد من أن العنصر ليس في حالة defunct
        if (context.mounted) {
          // ignore: invalid_use_of_protected_member
          setState(fn);
        }
      } catch (e) {
        // تجاهل أي أخطاء متعلقة بدورة حياة الwidget
        debugPrint('SafeSetState error ignored: $e');
      }
    }
  }
  
  /// فحص متقدم لحالة الwidget
  bool get canSafelySetState {
    try {
      return mounted && context.mounted;
    } catch (e) {
      return false;
    }
  }
}
