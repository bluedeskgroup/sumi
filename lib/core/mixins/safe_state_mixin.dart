import 'package:flutter/material.dart';

/// Mixin لحماية setState من الاستدعاء على widget تم التخلص منه
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// استدعاء setState آمن - يتحقق من mounted و _isDisposed
  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  /// تحقق من إمكانية استدعاء setState
  bool get canSetState => !_isDisposed && mounted;
}
