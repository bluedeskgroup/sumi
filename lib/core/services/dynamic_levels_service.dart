import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/core/models/dynamic_referral_level.dart';

class DynamicLevelsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static final DynamicLevelsService _instance = DynamicLevelsService._internal();
  factory DynamicLevelsService() => _instance;
  DynamicLevelsService._internal();

  List<DynamicReferralLevel> _cachedLevels = [];

  // Get active levels stream
  Stream<List<DynamicReferralLevel>> getActiveLevelsStream() {
    return _firestore
        .collection('referralLevels')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final levels = snapshot.docs
          .map((doc) => DynamicReferralLevel.fromMap(doc.id, doc.data()))
          .toList();
      
      // Sort by order locally to avoid index requirement
      levels.sort((a, b) => a.order.compareTo(b.order));
      
      _cachedLevels = levels;
      return levels;
    });
  }

  // Get cached levels (synchronous)
  List<DynamicReferralLevel> getCachedLevels() {
    return List.from(_cachedLevels);
  }

  // Get user's current level
  DynamicReferralLevel? getUserLevel(int referralsCount) {
    if (_cachedLevels.isEmpty) return null;
    
    return ReferralLevelCalculator.getUserLevel(referralsCount, _cachedLevels);
  }

  // Get next level for user
  DynamicReferralLevel? getNextLevel(int referralsCount) {
    if (_cachedLevels.isEmpty) return null;
    
    return ReferralLevelCalculator.getNextLevel(referralsCount, _cachedLevels);
  }

  // Get referrals needed for next level
  int getReferralsNeededForNextLevel(int referralsCount) {
    return ReferralLevelCalculator.getReferralsNeededForNextLevel(referralsCount, _cachedLevels);
  }

  // Initialize levels (load cache)
  Future<void> initializeLevels() async {
    try {
      final snapshot = await _firestore
          .collection('referralLevels')
          .where('isActive', isEqualTo: true)
          .get();
      
      final levels = snapshot.docs
          .map((doc) => DynamicReferralLevel.fromMap(doc.id, doc.data()))
          .toList();
      
      // Sort by order locally
      levels.sort((a, b) => a.order.compareTo(b.order));
      _cachedLevels = levels;
      
      // If no levels exist, create default ones
      if (_cachedLevels.isEmpty) {
        await _createDefaultLevels();
      }
    } catch (e) {
      print('Error initializing levels: $e');
      // Fallback to default levels structure
      _cachedLevels = _getStaticDefaultLevels();
    }
  }

  // Create default levels if none exist
  Future<void> _createDefaultLevels() async {
    try {
      final defaultLevels = DefaultReferralLevels.getDefaultLevels();
      final batch = _firestore.batch();
      
      for (final levelData in defaultLevels) {
        final ref = _firestore.collection('referralLevels').doc();
        batch.set(ref, levelData);
      }
      
      await batch.commit();
      
      // Reload levels after creation
      await initializeLevels();
    } catch (e) {
      print('Error creating default levels: $e');
    }
  }

  // Static fallback levels
  List<DynamicReferralLevel> _getStaticDefaultLevels() {
    return [
      DynamicReferralLevel(
        id: 'bronze',
        nameAr: 'البرونزية',
        nameEn: 'Bronze',
        percentage: 3,
        threshold: 0,
        colorHex: '#CD7F32',
        iconCode: '🥉',
        order: 1,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      DynamicReferralLevel(
        id: 'silver',
        nameAr: 'الفضية',
        nameEn: 'Silver',
        percentage: 4,
        threshold: 20,
        colorHex: '#C0C0C0',
        iconCode: '🥈',
        order: 2,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      DynamicReferralLevel(
        id: 'gold',
        nameAr: 'الذهبية',
        nameEn: 'Gold',
        percentage: 7,
        threshold: 50,
        colorHex: '#FFD700',
        iconCode: '🥇',
        order: 3,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Parse color from hex string
  int parseColorHex(String colorHex) {
    try {
      return int.parse(colorHex.substring(1), radix: 16) + 0xFF000000;
    } catch (e) {
      return 0xFF9A46D7; // Default purple color
    }
  }

  // Clean up resources
  void dispose() {
    _cachedLevels.clear();
  }
}