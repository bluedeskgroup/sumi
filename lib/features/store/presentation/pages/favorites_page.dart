import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: uid == null
          ? const Center(child: Text('الرجاء تسجيل الدخول'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('favorites')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد عناصر مفضلة'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    return Card(
                      child: ListTile(
                        title: Text(data['title'] ?? 'منتج'),
                        subtitle: Text(data['subtitle'] ?? ''),
                        trailing: Text('${(data['price'] ?? 0).toString()} ر.س'),
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


