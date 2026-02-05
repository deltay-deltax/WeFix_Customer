import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_routes.dart';

class WarrantyHistoryScreen extends StatelessWidget {
  const WarrantyHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Login to view warranties')),
      );
    }
    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('warranties')
        .orderBy('createdAt', descending: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Warranty History')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No warranties yet'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final id = docs[i].id;
              final date = (d['purchaseDate'] as Timestamp?)?.toDate();
              final title = (d['modelName'] ?? 'Unknown').toString();
              final subtitle = [
                if (d['company'] != null && d['company'].toString().isNotEmpty)
                  d['company'],
                if (d['modelNumber'] != null &&
                    d['modelNumber'].toString().isNotEmpty)
                  'Model: ${d['modelNumber']}',
                if (date != null) date.toLocal().toString().split(' ').first,
              ].join('  •  ');
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.verified_user)),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.warrantyDetail,
                  arguments: {'id': id, 'data': d},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
