import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/scanned_card_model.dart';

class CardScanSuccessDialog extends StatelessWidget {
  final ScannedCardModel scannedCard;
  final VoidCallback onViewDetails;

  const CardScanSuccessDialog({
    super.key,
    required this.scannedCard,
    required this.onViewDetails,
  });

  static Future<void> show(
    BuildContext context, {
    required ScannedCardModel scannedCard,
    required VoidCallback onViewDetails,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CardScanSuccessDialog(
        scannedCard: scannedCard,
        onViewDetails: onViewDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 327,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF20C9AC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Color(0xFF20C9AC),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'تم مسح البطاقة بنجاح!',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF1D2035),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Card details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE7EBEF)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('كود البطاقة', scannedCard.displayCode),
                    const SizedBox(height: 8),
                    _buildDetailRow('اسم العميل', scannedCard.customerName),
                    const SizedBox(height: 8),
                    _buildDetailRow('رقم الهاتف', scannedCard.customerPhone),
                    const SizedBox(height: 8),
                    _buildDetailRow('نوع البطاقة', scannedCard.cardType),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onViewDetails();
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF20C9AC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'عرض تفاصيل الطلب',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Close button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7EBEF)),
                  ),
                  child: const Center(
                    child: Text(
                      'إغلاق',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF637D92),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF1D2035),
            ),
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF637D92),
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
