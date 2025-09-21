class ScannedCardModel {
  final String cardCode;
  final String cardType;
  final String format;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final DateTime scannedAt;
  final bool isValid;
  final String? errorMessage;

  ScannedCardModel({
    required this.cardCode,
    required this.cardType,
    required this.format,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.scannedAt,
    required this.isValid,
    this.errorMessage,
  });

  factory ScannedCardModel.fromScanResult(Map<String, dynamic> scanResult, {Map<String, dynamic>? customerData}) {
    final code = scanResult['code'] as String;
    final isValid = _validateCardCode(code);
    
    return ScannedCardModel(
      cardCode: code,
      cardType: scanResult['type'] ?? 'qrCode',
      format: scanResult['format'] ?? 'unknown',
      customerId: customerData?['customerId'] ?? 'customer_${code.substring(code.length >= 6 ? code.length - 6 : 0)}',
      customerName: customerData?['customerName'] ?? 'مي عمرو السيد', // من قاعدة البيانات أو افتراضي
      customerPhone: customerData?['customerPhone'] ?? '01091158519', // من قاعدة البيانات أو افتراضي
      scannedAt: DateTime.now(),
      isValid: isValid,
      errorMessage: isValid ? null : _getErrorMessage(code),
    );
  }

  static String _getErrorMessage(String code) {
    if (code.length < 8) {
      return 'كود البطاقة قصير جداً';
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code.toUpperCase())) {
      return 'تنسيق البطاقة غير صحيح';
    }
    return 'البطاقة غير صالحة أو منتهية الصلاحية';
  }

  factory ScannedCardModel.fromMap(Map<String, dynamic> map) {
    return ScannedCardModel(
      cardCode: map['cardCode'] ?? '',
      cardType: map['cardType'] ?? '',
      format: map['format'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      scannedAt: DateTime.parse(map['scannedAt']),
      isValid: map['isValid'] ?? false,
      errorMessage: map['errorMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardCode': cardCode,
      'cardType': cardType,
      'format': format,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'scannedAt': scannedAt.toIso8601String(),
      'isValid': isValid,
      'errorMessage': errorMessage,
    };
  }

  static bool _validateCardCode(String code) {
    // قواعد التحقق من البطاقة:
    // 1. يجب أن يكون طول الكود أكثر من 8 أحرف
    // 2. يجب أن يبدأ بـ "SUM" للبطاقات الصالحة
    // 3. يجب أن يحتوي على أرقام
    
    if (code.length < 8) return false;
    if (code.toUpperCase().startsWith('SUM')) return true;
    if (RegExp(r'\d{8,}').hasMatch(code)) return true;
    
    return false;
  }

  String get displayCode {
    if (cardCode.length > 10) {
      return '${cardCode.substring(0, 4)}***${cardCode.substring(cardCode.length - 4)}';
    }
    return cardCode;
  }

  String get statusText {
    if (isValid) {
      return 'بطاقة صالحة ✓';
    } else {
      return errorMessage ?? 'بطاقة غير صالحة ✗';
    }
  }

  CardValidationStatus get validationStatus {
    if (isValid) return CardValidationStatus.valid;
    if (errorMessage?.contains('منتهية') == true) return CardValidationStatus.expired;
    return CardValidationStatus.invalid;
  }
}

enum CardValidationStatus {
  valid,
  invalid,
  expired,
}
