import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/wallet/models/wallet_transaction.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _walletDoc => _db
      .collection('users')
      .doc(_uid)
      .collection('meta')
      .doc('wallet');

  CollectionReference<Map<String, dynamic>> get _txCol => _db
      .collection('users')
      .doc(_uid)
      .collection('wallet_transactions');

  Stream<double> balanceStream() {
    if (_uid == null) return const Stream.empty();
    return _walletDoc.snapshots().map((d) => (d.data()?['balance'] ?? 0).toDouble());
  }

  Future<double> getBalance() async {
    if (_uid == null) return 0;
    final d = await _walletDoc.get();
    return (d.data()?['balance'] ?? 0).toDouble();
  }

  Stream<List<WalletTransactionModel>> transactionsStream() {
    if (_uid == null) return const Stream.empty();
    return _txCol.orderBy('createdAt', descending: true).snapshots().map(
          (s) => s.docs
              .map((d) => WalletTransactionModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> credit({required double amount, required String title, String? reference}) async {
    await _addTransaction(type: 'credit', amount: amount, title: title, reference: reference);
  }

  Future<void> debit({required double amount, required String title, String? reference}) async {
    await _addTransaction(type: 'debit', amount: amount, title: title, reference: reference);
  }

  Future<void> _addTransaction({required String type, required double amount, required String title, String? reference}) async {
    if (_uid == null) return;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_walletDoc);
      final current = (snap.data()?['balance'] ?? 0).toDouble();
      final newBalance = type == 'credit' ? current + amount : current - amount;
      if (newBalance < 0) {
        throw Exception('Insufficient wallet balance');
      }
      tx.set(_walletDoc, {'balance': newBalance}, SetOptions(merge: true));
      final ref = _txCol.doc();
      tx.set(ref, WalletTransactionModel(
        id: ref.id,
        type: type,
        amount: amount,
        title: title,
        reference: reference,
        createdAt: DateTime.now(),
      ).toMap());
    });
  }
}


