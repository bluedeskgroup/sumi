import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/auth/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<List<AppUser>> getUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      final List<AppUser> users = [];
      for (String userId in userIds) {
        final user = await getUser(userId);
        if (user != null) {
          users.add(user);
        }
      }
      return users;
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }
} 