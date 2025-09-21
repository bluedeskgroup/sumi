import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/auth/models/address_model.dart';

class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _col => _firestore
      .collection('users')
      .doc(_uid)
      .collection('addresses');

  Stream<List<AddressModel>> streamAddresses() {
    if (_uid == null) return const Stream.empty();
    return _col.orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs
          .map((d) => AddressModel.fromMap(d.id, d.data()))
          .toList(),
    );
  }

  Future<String?> addAddress(AddressModel address) async {
    if (_uid == null) return null;
    final doc = _col.doc();
    await doc.set(address.copyWith(id: doc.id).toMap());
    return doc.id;
  }

  Future<void> updateAddress(AddressModel address) async {
    if (_uid == null) return;
    await _col.doc(address.id).set(address.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteAddress(String id) async {
    if (_uid == null) return;
    await _col.doc(id).delete();
  }

  Future<void> setDefault(String id) async {
    if (_uid == null) return;
    final batch = _firestore.batch();
    final docs = await _col.get();
    for (final d in docs.docs) {
      batch.update(d.reference, {'isDefault': d.id == id});
    }
    await batch.commit();
  }

  Future<AddressModel?> getDefaultAddress() async {
    if (_uid == null) return null;
    final q = await _col.where('isDefault', isEqualTo: true).limit(1).get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return AddressModel.fromMap(d.id, d.data());
  }

  Future<List<AddressModel>> getAddressesOnce() async {
    if (_uid == null) return [];
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => AddressModel.fromMap(d.id, d.data())).toList();
  }
}


