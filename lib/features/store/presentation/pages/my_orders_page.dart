import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الشراء'),
      ),
      body: uid == null
          ? const Center(child: Text('الرجاء تسجيل الدخول'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات بعد'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final orderId = docs[i].id;
                    final total = (data['total'] ?? 0).toDouble();
                    final status = data['status'] ?? 'pending';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    return Card(
                      child: ListTile(
                        title: Text('طلب #$orderId'),
                        subtitle: Text(createdAt != null ? createdAt.toString() : ''),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${total.toStringAsFixed(2)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        onTap: () {},
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}


