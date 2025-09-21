class WalletTransactionModel {
  final String id;
  final String type; // credit | debit
  final double amount;
  final String title;
  final String? reference;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.title,
    this.reference,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromMap(String id, Map<String, dynamic> data) {
    return WalletTransactionModel(
      id: id,
      type: data['type'] ?? 'debit',
      amount: (data['amount'] ?? 0).toDouble(),
      title: data['title'] ?? '',
      reference: data['reference'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'title': title,
      'reference': reference,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}


