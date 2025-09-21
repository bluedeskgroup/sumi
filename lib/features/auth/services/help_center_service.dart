import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/auth/models/help_center_settings.dart';

class HelpCenterService {
  static final HelpCenterService _instance = HelpCenterService._internal();
  factory HelpCenterService() => _instance;
  HelpCenterService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<HelpCenterSettings> getSettings() async {
    try {
      final doc = await _firestore.collection('app_settings').doc('help_center').get();
      if (doc.exists) {
        return HelpCenterSettings.fromMap(doc.data() ?? {});
      }
      return const HelpCenterSettings();
    } catch (_) {
      return const HelpCenterSettings();
    }
  }
}


