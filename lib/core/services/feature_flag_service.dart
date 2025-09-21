import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/core/models/feature_flag_model.dart';
import 'package:flutter/foundation.dart';

class FeatureFlagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _featureFlagsCollection =
      FirebaseFirestore.instance.collection('feature_flags');

  // A cache for the feature flags to avoid multiple reads
  Map<String, bool>? _featureFlagsCache;

  // Fetches all feature flags and caches them
  Future<void> _fetchAndCacheFeatureFlags() async {
    try {
      final snapshot = await _featureFlagsCollection.get();
      final flags = snapshot.docs.map((doc) => FeatureFlag.fromFirestore(doc)).toList();
      _featureFlagsCache = {for (var flag in flags) flag.id: flag.isEnabled};
    } catch (e) {
      // In case of error (e.g., offline), default to all features enabled
      debugPrint("Error fetching feature flags: $e. Defaulting to all enabled.");
      _featureFlagsCache = {
        'store': true,
        'community': true,
        'services': true,
        'video': true,
      };
    }
  }

  // Gets the status of a specific feature.
  // It will fetch from the network on the first call and use cache for subsequent calls.
  Future<bool> isFeatureEnabled(String featureId) async {
    if (_featureFlagsCache == null) {
      await _fetchAndCacheFeatureFlags();
    }
    // Default to true if a specific flag is not found in the cache for any reason
    return _featureFlagsCache?[featureId] ?? true;
  }
} 