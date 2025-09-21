import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:sumi/features/auth/services/auth_service.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:sumi/core/services/user_type_service.dart';
import 'package:sumi/features/auth/presentation/pages/auth_gate.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  const OtpPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  late String _currentVerificationId;
  bool _isLoading = false;

  // Resend Timer
  late Timer _timer;
  int _start = 120; // دقيقتين لتتماشى مع timeout الجديد
  bool _isResendButtonActive = false;
  
  // Resend token لإرسال كود جديد
  int? _resendToken;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _resendToken = widget.resendToken; // حفظ resend token
    startTimer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void startTimer() {
    _isResendButtonActive = false;
    _start = 120; // دقيقتين - الحد الأقصى من Firebase
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            _isResendButtonActive = true;
            timer.cancel();
          });
          
          // Show expired warning
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'انتهت صلاحية الكود. يرجى طلب كود جديد.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                action: SnackBarAction(
                  label: 'إرسال كود جديد',
                  textColor: Colors.white,
                  onPressed: _resendCode,
                ),
              ),
            );
          }
        } else {
          setState(() {
            _start--;
          });
          
          // Warning when 30 seconds left
          if (_start == 30 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '⏰ تبقى 30 ثانية على انتهاء صلاحية الكود',
                  style: TextStyle(fontSize: 14),
                ),
                backgroundColor: Colors.orange.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) return;
    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: _otpController.text.trim(),
      );
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // إنشاء ملف المستخدم في Firestore إذا كان مستخدم جديد
      if (userCredential.user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        await CommunityService().createUserProfile(userCredential.user!);
      }
      
      // حفظ نوع المستخدم كمستخدم عادي
      await UserTypeService.saveUserType(
        UserTypeService.typeUser,
        userData: {
          'phoneNumber': widget.phoneNumber,
          'loginMethod': 'phone',
          'uid': userCredential.user?.uid ?? '',
        },
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('تم تسجيل الدخول بنجاح!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Navigate to home after successful verification
        // Go back to AuthGate and let it handle proper navigation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        bool showResendOption = false;
        
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = 'الكود المدخل غير صحيح. تأكد من إدخال الكود الصحيح.';
            break;
          case 'session-expired':
          case 'code-expired':
            errorMessage = 'انتهت صلاحية الكود. يرجى طلب كود جديد.';
            showResendOption = true;
            break;
          case 'invalid-phone-number':
            errorMessage = 'رقم الهاتف غير صحيح.';
            break;
          case 'too-many-requests':
            errorMessage = 'تم حظر الجهاز مؤقتاً بسبب كثرة المحاولات. حاول مرة أخرى بعد ساعة أو استخدم Google.';
            break;
          default:
            errorMessage = 'خطأ في التحقق من الكود: ${e.message}';
        }
        
        // Clear the OTP field for invalid codes
        if (e.code == 'invalid-verification-code') {
          _otpController.clear();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
            action: showResendOption
                ? SnackBarAction(
                    label: 'إرسال كود جديد',
                    textColor: Colors.white,
                    onPressed: () {
                      // إغلاق الـ snackbar الحالي وإرسال كود جديد
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      _resendCode();
                    },
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    
    debugPrint('Resending code for: ${widget.phoneNumber} with token: $_resendToken');

    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('جاري إرسال كود جديد...'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    await _authService.signInWithPhone(
        phoneNumber: widget.phoneNumber,
        forceResendingToken: _resendToken, // استخدام resend token
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) setState(() => _isLoading = false);
          } catch (e) {
            debugPrint('Auto verification failed: $e');
            if (mounted) setState(() => _isLoading = false);
          }
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            String errorMessage;
            bool showGoogleSignInOption = false;
            
            switch (e.code) {
              case 'sms-blocked':
                errorMessage = e.message ?? 'خدمة SMS مؤقتاً غير متاحة';
                showGoogleSignInOption = true;
                break;
              case 'too-many-requests':
                errorMessage = 'تم حظر الجهاز مؤقتاً بسبب كثرة المحاولات. حاول مرة أخرى بعد ساعة أو استخدم Google.';
                showGoogleSignInOption = true;
                break;
              case 'invalid-phone-number':
                errorMessage = 'رقم الهاتف غير صحيح.';
                break;
              case 'quota-exceeded':
                errorMessage = 'تم تجاوز حد الإرسال اليومي. حاول غداً.';
                showGoogleSignInOption = true;
                break;
              default:
                errorMessage = 'فشل في إرسال الكود: ${e.message}';
                showGoogleSignInOption = true;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 6),
                action: showGoogleSignInOption
                    ? SnackBarAction(
                        label: 'تسجيل دخول بـ Google',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          _tryGoogleSignIn();
                        },
                      )
                    : null,
              ),
            );
          }
        },
        codeSent: (verificationId, newResendToken) {
          if (mounted) {
            setState(() {
              _currentVerificationId = verificationId;
              _resendToken = newResendToken; // حفظ resend token الجديد
              _isLoading = false;
            });
            startTimer();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('تم إرسال كود جديد إلى ${widget.phoneNumber}'),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (mounted) {
            setState(() {
              _currentVerificationId = verificationId;
              _isLoading = false;
            });
          }
        });
  }

  // Try Google Sign-in as fallback
  Future<void> _tryGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.signInWithGoogle();
      
      // التأكد من إيقاف حالة التحميل
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      if (user != null && mounted) {
        // حفظ نوع المستخدم كمستخدم عادي
        await UserTypeService.saveUserType(
          UserTypeService.typeUser,
          userData: {
            'email': user.user?.email ?? '',
            'displayName': user.user?.displayName ?? '',
            'photoURL': user.user?.photoURL ?? '',
            'loginMethod': 'google',
          },
        );
        
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('تم تسجيل الدخول بنجاح باستخدام Google!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Navigate to home after successful Google sign-in
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (Route<dynamic> route) => false,
        );
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('فشل في تسجيل الدخول باستخدام Google'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الدخول: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
          fontSize: 22, color: isDarkMode ? Colors.white : const Color(0xFF3E115A)),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
          )
        ]
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDarkMode ? Colors.white : Colors.black),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.black, Colors.grey[850]!]
                : [const Color(0xFFE6F1FC), const Color(0xFFFFD7EA)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations.otpAppBarTitle,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${localizations.otpPageInstruction} ${widget.phoneNumber}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    Pinput(
                      length: 6,
                      controller: _otpController,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: const Color(0xFF3E115A), width: 2),
                        ),
                      ),
                      submittedPinTheme: defaultPinTheme.copyWith(
                         decoration: defaultPinTheme.decoration!.copyWith(
                          color: isDarkMode ? Colors.grey[800] : const Color(0xFFE6F1FC),
                          border: Border.all(color: const Color(0xFF3E115A)),
                        ),
                      ),
                      onCompleted: (pin) => _verifyOtp(),
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                              onPressed: _otpController.text.length == 6 ? _verifyOtp : null,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF3E115A),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                                shadowColor: Colors.black.withAlpha(51),
                              ),
                              child: Text(
                                localizations.otpVerifyButton,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    const SizedBox(height: 20),
                    
                    // Google Sign-in alternative
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'مشاكل في استقبال الكود؟',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _tryGoogleSignIn,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_circle, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'جرب تسجيل الدخول بـ Google',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: Directionality.of(context),
                      children: [
                        Text(
                          localizations.otpDidNotReceiveCode,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: _isResendButtonActive ? _resendCode : null,
                          child: Text(
                            _isResendButtonActive
                                ? localizations.otpResendCode
                                : '${localizations.otpResendIn} ${_formatTime(_start)}',
                            style: TextStyle(
                              color: _isResendButtonActive
                                  ? const Color(0xFF9A46D7)
                                  : (_start < 30 ? Colors.orange : Colors.grey),
                              fontWeight: FontWeight.bold,
                              fontSize: _start < 30 ? 14 : 13,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 