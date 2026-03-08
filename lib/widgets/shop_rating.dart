import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopRating extends StatelessWidget {
  final String shopId;

  const ShopRating({Key? key, required this.shopId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shop_users')
          .doc(shopId)
          .collection('ratings')
          .snapshots(),
      builder: (context, snapshot) {
        double avg = 0.0;
        int count = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final docs = snapshot.data!.docs;
          count = docs.length;
          final total = docs.fold<double>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum +
                (data['rating'] is int
                    ? (data['rating'] as int).toDouble()
                    : (data['rating'] as double? ?? 0.0));
          });
          avg = total / count;
        }

        return Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              count == 0 ? 'New' : '${avg.toStringAsFixed(1)}  •  $count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        );
      },
    );
  }
}
