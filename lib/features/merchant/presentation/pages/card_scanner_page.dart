import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import '../../models/scanned_card_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/card_scan_success_dialog.dart';

class CardScannerPage extends StatefulWidget {
  const CardScannerPage({super.key});

  @override
  State<CardScannerPage> createState() => _CardScannerPageState();
}

class _CardScannerPageState extends State<CardScannerPage>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _isPermissionGranted = false;
  bool _isScanning = true;
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _controller == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (_isPermissionGranted) {
          _controller!.start();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _controller!.stop();
        break;
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    setState(() {
      _isPermissionGranted = status == PermissionStatus.granted;
    });

    if (_isPermissionGranted) {
      _initializeScanner();
    }
  }

  void _initializeScanner() {
    _controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.code39],
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      
      setState(() {
        _scannedCode = barcode.rawValue ?? 'Unknown';
        _isScanning = false;
      });

      _processScannedCard(barcode);
    }
  }

  Future<void> _processScannedCard(Barcode barcode) async {
    try {
      final cardCode = barcode.rawValue ?? '';
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get customer data from database
      final customerData = await CardScanService.getCustomerByCard(cardCode);
      
      final scanResult = {
        'code': cardCode,
        'type': barcode.type.name,
        'format': barcode.format.name,
      };

      // Create scanned card model with real customer data
      final scannedCard = ScannedCardModel.fromScanResult(
        scanResult, 
        customerData: customerData
      );
      
      // Update validation based on database check
      final isValidInDatabase = await CardScanService.validateCardInDatabase(cardCode);
      final updatedCard = ScannedCardModel(
        cardCode: scannedCard.cardCode,
        cardType: scannedCard.cardType,
        format: scannedCard.format,
        customerId: scannedCard.customerId,
        customerName: scannedCard.customerName,
        customerPhone: scannedCard.customerPhone,
        scannedAt: scannedCard.scannedAt,
        isValid: scannedCard.isValid && isValidInDatabase,
        errorMessage: scannedCard.isValid && isValidInDatabase ? null : 
            (customerData == null ? 'البطاقة غير مسجلة في النظام' : scannedCard.errorMessage),
      );
      
      // Save to Firebase
      await CardScanService.saveScannedCard(updatedCard.toMap());

      // Close loading dialog
      Navigator.pop(context);

      // Show validation result
      if (updatedCard.isValid) {
        _showSuccessDialog(updatedCard);
      } else {
        _showErrorDialog(updatedCard);
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في معالجة البطاقة: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _resetScanner();
    }
  }

  void _showSuccessDialog(ScannedCardModel card) {
    CardScanSuccessDialog.show(
      context,
      scannedCard: card,
      onViewDetails: () {
        // Return the scanned card data and close scanner
        Navigator.pop(context, card.toMap());
      },
    );
  }

  void _showErrorDialog(ScannedCardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ في البطاقة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('كود البطاقة: ${card.displayCode}'),
            Text('المشكلة: ${card.errorMessage}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _resetScanner(); // Try again
            },
            child: const Text('إعادة المحاولة'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous page
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _scannedCode = null;
      _isScanning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        body: Stack(
          children: [
            // Camera preview
            if (_isPermissionGranted && _controller != null)
              MobileScanner(
                controller: _controller!,
                onDetect: _onDetect,
                fit: BoxFit.cover,
              )
            else
              _buildPermissionDeniedView(),

            // Scanner overlay
            _buildScannerOverlay(),

            // Close button
            _buildCloseButton(),

            // Bottom content
            _buildBottomContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'يرجى منح الإذن للوصول إلى الكاميرا',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
      ),
      child: Stack(
        children: [
          // Scanning frame
          Center(
            child: Container(
              width: 395,
              height: 224,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Corner brackets
                  _buildCornerBracket(Alignment.topLeft),
                  _buildCornerBracket(Alignment.topRight),
                  _buildCornerBracket(Alignment.bottomLeft),
                  _buildCornerBracket(Alignment.bottomRight),
                ],
              ),
            ),
          ),

          // Background image placeholder
          Positioned(
            left: 24,
            top: 261,
            child: Container(
              width: 382,
              height: 210,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.credit_card,
                  size: 48,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: Color(0xFF9A46D7), width: 3)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: Color(0xFF9A46D7), width: 3)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: Color(0xFF9A46D7), width: 3)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: Color(0xFF9A46D7), width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 68,
      right: 24,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF3D4444),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Center(
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomContent() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 210,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Column(
          children: [
            // Title and description
            Container(
              width: 382,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 35,
                    child: Text(
                      'ضع بطاقة سومي في الاطار لتسجيل البيانات',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                        height: 1,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(height: 2),
                  SizedBox(
                    height: 26,
                    child: Text(
                      'يجب أن تكون بطاقة العميل المسجل ويجب أن تكون بطاقة فعاله .',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xFFBFBFBF),
                        height: 1.33,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                // Retry button
                Expanded(
                  child: GestureDetector(
                    onTap: _resetScanner,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF323F49)),
                      ),
                      child: const Center(
                        child: Text(
                          'اعادة المحاوله',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF323F49),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Scan card button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isScanning && _scannedCode != null) {
                        Navigator.pop(context, {
                          'code': _scannedCode,
                          'type': 'manual',
                          'format': 'unknown',
                        });
                      } else {
                        _resetScanner();
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9A46D7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'مسح البطاقة',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
    );
  }
}

// Service class to manage scanned card data
class CardScanService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveScannedCard(Map<String, dynamic> cardData) async {
    try {
      // Save to Firebase collection 'scanned_cards'
      await _firestore.collection('scanned_cards').add({
        ...cardData,
        'merchantId': 'merchant_123', // في التطبيق الحقيقي يجب الحصول على معرف التاجر الحالي
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Card data saved to Firebase: ${cardData['cardCode']}');
    } catch (e) {
      debugPrint('Error saving card data: $e');
      throw e;
    }
  }

  static Future<List<Map<String, dynamic>>> getScannedCards(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('scanned_cards')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error retrieving scanned cards: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLastScannedCard(String merchantId) async {
    try {
      final cards = await getScannedCards(merchantId);
      return cards.isNotEmpty ? cards.first : null;
    } catch (e) {
      debugPrint('Error getting last scanned card: $e');
      return null;
    }
  }

  static Future<bool> validateCardInDatabase(String cardCode) async {
    try {
      // في التطبيق الحقيقي، يجب التحقق من قاعدة بيانات البطاقات
      final snapshot = await _firestore
          .collection('customer_cards')
          .where('cardCode', isEqualTo: cardCode)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating card: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCustomerByCard(String cardCode) async {
    try {
      final snapshot = await _firestore
          .collection('customer_cards')
          .where('cardCode', isEqualTo: cardCode)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final cardDoc = snapshot.docs.first;
        final customerId = cardDoc.data()['customerId'];
        
        // Get customer details
        final customerDoc = await _firestore
            .collection('users')
            .doc(customerId)
            .get();
        
        if (customerDoc.exists) {
          return {
            'customerId': customerId,
            'customerName': customerDoc.data()?['displayName'] ?? 'غير محدد',
            'customerPhone': customerDoc.data()?['phoneNumber'] ?? 'غير محدد',
            'cardCode': cardCode,
            'cardType': cardDoc.data()['cardType'] ?? 'standard',
          };
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting customer by card: $e');
      return null;
    }
  }

  static bool isValidCardFormat(String code) {
    // Basic validation - in real app, implement proper card validation
    return code.isNotEmpty && code.length >= 8;
  }
}
