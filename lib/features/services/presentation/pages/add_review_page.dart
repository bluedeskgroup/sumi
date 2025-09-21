import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:sumi/features/auth/services/auth_service.dart';
import 'package:sumi/features/services/services/services_service.dart';

class AddReviewPage extends StatefulWidget {
  final String providerId;

  const AddReviewPage({super.key, required this.providerId});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 3.0;
  bool _isSubmitting = false;

  final ServicesService _servicesService = ServicesService();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        // Should not happen if the button is only shown to logged in users
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب عليك تسجيل الدخول أولاً.')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      try {
        await _servicesService.addReview(
          providerId: widget.providerId,
          userId: currentUser.uid,
          userName: currentUser.displayName ?? 'مستخدم غير معروف',
          userImageUrl: currentUser.photoURL,
          rating: _rating,
          comment: _commentController.text,
        );

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('شكراً لك، تم إضافة تقييمك بنجاح!')),
          );
          Navigator.of(context).pop(true); // Pop with a result to indicate success
        }
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ ما: $e')),
          );
        }
      } finally {
         if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة تقييم'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تقييمك يهمنا',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'اكتب تعليقك هنا...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال تعليق.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                     backgroundColor: Colors.purple[700],
                     foregroundColor: Colors.white
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('إرسال التقييم'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 