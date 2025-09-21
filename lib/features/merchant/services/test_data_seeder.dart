import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TestDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create sample customer cards for testing the scanner
  static Future<void> createSampleCustomerCards() async {
    try {
      final sampleCards = [
        {
          'cardCode': 'SUM123456789',
          'customerId': 'customer_001',
          'cardType': 'gold',
          'isActive': true,
          'issueDate': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'expiryDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'cardCode': 'SUM987654321',
          'customerId': 'customer_002',
          'cardType': 'silver',
          'isActive': true,
          'issueDate': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          'expiryDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'cardCode': '1234567890',
          'customerId': 'customer_003',
          'cardType': 'standard',
          'isActive': true,
          'issueDate': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          'expiryDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'cardCode': 'EXPIRED123',
          'customerId': 'customer_004',
          'cardType': 'standard',
          'isActive': false,
          'issueDate': DateTime.now().subtract(const Duration(days: 400)).toIso8601String(),
          'expiryDate': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final card in sampleCards) {
        await _firestore.collection('customer_cards').add(card);
      }

      debugPrint('Sample customer cards created successfully');
    } catch (e) {
      debugPrint('Error creating sample customer cards: $e');
    }
  }

  /// Create sample customer users for testing
  static Future<void> createSampleCustomers() async {
    try {
      final sampleCustomers = [
        {
          'uid': 'customer_001',
          'displayName': 'مي عمرو السيد',
          'phoneNumber': '+966570151550',
          'email': 'mai.amr@example.com',
          'photoURL': 'https://via.placeholder.com/150',
          'createdAt': FieldValue.serverTimestamp(),
          'searchKeywords': ['مي', 'عمرو', 'السيد', 'mai', 'amr'],
        },
        {
          'uid': 'customer_002',
          'displayName': 'أحمد محمد علي',
          'phoneNumber': '+966555123456',
          'email': 'ahmed.mohammed@example.com',
          'photoURL': 'https://via.placeholder.com/150',
          'createdAt': FieldValue.serverTimestamp(),
          'searchKeywords': ['أحمد', 'محمد', 'علي', 'ahmed', 'mohammed'],
        },
        {
          'uid': 'customer_003',
          'displayName': 'فاطمة أحمد',
          'phoneNumber': '+966566789012',
          'email': 'fatima.ahmed@example.com',
          'photoURL': 'https://via.placeholder.com/150',
          'createdAt': FieldValue.serverTimestamp(),
          'searchKeywords': ['فاطمة', 'أحمد', 'fatima', 'ahmed'],
        },
        {
          'uid': 'customer_004',
          'displayName': 'عبد الله سالم',
          'phoneNumber': '+966577890123',
          'email': 'abdullah.salem@example.com',
          'photoURL': 'https://via.placeholder.com/150',
          'createdAt': FieldValue.serverTimestamp(),
          'searchKeywords': ['عبد', 'الله', 'سالم', 'abdullah', 'salem'],
        },
      ];

      for (final customer in sampleCustomers) {
        await _firestore.collection('users').doc(customer['uid'] as String).set(customer);
      }

      debugPrint('Sample customers created successfully');
    } catch (e) {
      debugPrint('Error creating sample customers: $e');
    }
  }

  /// Seed all test data
  static Future<void> seedAllTestData() async {
    await createSampleCustomers();
    await createSampleCustomerCards();
    debugPrint('All test data seeded successfully');
  }

  /// Clear all test data (for cleanup)
  static Future<void> clearTestData() async {
    try {
      // Delete customer cards
      final cardsSnapshot = await _firestore.collection('customer_cards').get();
      for (final doc in cardsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete test customer users
      final testCustomerIds = ['customer_001', 'customer_002', 'customer_003', 'customer_004'];
      for (final customerId in testCustomerIds) {
        await _firestore.collection('users').doc(customerId).delete();
      }

      // Delete scanned cards
      final scannedCardsSnapshot = await _firestore.collection('scanned_cards').get();
      for (final doc in scannedCardsSnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('Test data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing test data: $e');
    }
  }

  /// Generate QR codes for testing (returns list of valid codes)
  static List<String> getTestQRCodes() {
    return [
      'SUM123456789', // Valid Gold Card
      'SUM987654321', // Valid Silver Card  
      '1234567890',   // Valid Standard Card
      'EXPIRED123',   // Expired Card
      'INVALID12',    // Invalid (too short)
      'SUM000000000', // Invalid (not in database)
    ];
  }

  /// Print test codes for manual testing
  static void printTestCodes() {
    final codes = getTestQRCodes();
    debugPrint('=== TEST QR CODES FOR CARD SCANNER ===');
    debugPrint('Valid Gold Card: ${codes[0]}');
    debugPrint('Valid Silver Card: ${codes[1]}');
    debugPrint('Valid Standard Card: ${codes[2]}');
    debugPrint('Expired Card: ${codes[3]}');
    debugPrint('Invalid (too short): ${codes[4]}');
    debugPrint('Invalid (not in database): ${codes[5]}');
    debugPrint('======================================');
  }
}
