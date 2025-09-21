import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class DeleteConfirmationDialog extends StatelessWidget {
  final String itemName;
  final bool isService;

  const DeleteConfirmationDialog({
    super.key,
    required this.itemName,
    required this.isService,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String itemName,
    required bool isService,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteConfirmationDialog(
        itemName: itemName,
        isService: isService,
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
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFADCDF),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 32,
                  color: Color(0xFFE32B3D),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                isService ? 'حذف الخدمة' : 'حذف المنتج',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF1D2035),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                'هل أنت متأكد من حذف ${isService ? 'الخدمة' : 'المنتج'} "$itemName"؟',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF637D92),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'لن تتمكن من التراجع عن هذا الإجراء.',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF637D92),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE7EBEF)),
                        ),
                        child: const Center(
                          child: Text(
                            'البقاء',
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
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Delete button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE32B3D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            isService ? 'حذف الخدمة' : 'حذف المنتج',
                            style: const TextStyle(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
