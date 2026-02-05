import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ProductDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final shopId = data['shopId'] as String?;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [if (shopId != null) _FavoriteHeart(shopId: shopId)],
      ),
      body: shopId == null
          ? _fallbackBody(context)
          : _shopBody(context, shopId),
    );
  }

  Widget _shopBody(BuildContext context, String shopId) {
    final shopDoc = FirebaseFirestore.instance
        .collection('shop_users')
        .doc(shopId);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: shopDoc.snapshots(),
      builder: (context, shopSnap) {
        if (!shopSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = shopSnap.data!.data() ?? {};
        final title =
            (data['companyLegalName'] ??
                    data['companyLegalname'] ??
                    data['companylegalName'] ??
                    'Shop')
                .toString();
        final image = data['imageUrl'] as String?;
        final description = (data['shopDescription'] ?? '').toString();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: image != null && image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                if (data['gmapUrl'] != null &&
                    (data['gmapUrl'] as String).isNotEmpty)
                  InkWell(
                    onTap: () => _launchMapUrl(data['gmapUrl'] as String),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            
            // --- UPDATED: Dynamic Ratings ---
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: shopDoc.collection('ratings').snapshots(),
              builder: (context, ratingSnap) {
                final ratings = ratingSnap.data?.docs ?? [];
                double avg = 0;
                if (ratings.isNotEmpty) {
                  final total = ratings.fold<double>(
                      0, (sum, doc) => sum + (doc.data()['rating'] ?? 0));
                  avg = total / ratings.length;
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                         const Icon(Icons.star, color: Colors.amber, size: 20),
                         const SizedBox(width: 4),
                         Text(
                           ratings.isEmpty ? 'New' : '${avg.toStringAsFixed(1)}  •  ${ratings.length} ratings',
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                         ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    if (description.isNotEmpty) ...[
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(description),
                      const SizedBox(height: 12),
                    ],
                    
                    const Text(
                      'Services',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: shopDoc.collection('services').snapshots(),
                      builder: (context, svcSnap) {
                        if (svcSnap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final svcs = svcSnap.data?.docs ?? [];
                        if (svcs.isEmpty) {
                          return const Text('No services listed');
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: svcs.map((d) {
                            final s = d.data();
                            final name = (s['name'] ?? 'Service').toString();
                            final amount = s['amount'];
                            final price = amount == null ? '-' : '₹$amount';
                            return _servicePill(name, price);
                          }).toList(),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 18),
                    // Updated Action Buttons with Orange Color
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final id = await _createOrOpenChat(
                                shopId,
                                title,
                                image,
                              );
                              if (id == null) return;
                              if (!context.mounted) return;
                              Navigator.pushNamed(
                                context,
                                AppRoutes.chatDetail,
                                arguments: {
                                  'chatId': id,
                                  'title': title,
                                  'image': image,
                                },
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Chat'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.requestService,
                              arguments: {'shopId': shopId},
                            ),
                            icon: const Icon(
                              Icons.assignment_turned_in_outlined,
                            ),
                            label: const Text('Request'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // --- Top 5 Ratings Section ---
                     // --- Top 5 Ratings Section ---
                    if (ratings.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Recent Reviews',
                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...ratings.take(5).map((d) {
                         final rData = d.data();
                         final rVal = rData['rating'] ?? 0;
                         final rName = rData['userName'] ?? 'User';
                         final rAvatar = rData['userAvatar'] as String?;
                         final rReview = rData['review'] as String?;
                         final rDate = rData['ratedAt'] as Timestamp?;

                         return Container(
                           margin: const EdgeInsets.only(bottom: 16),
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(20),
                             boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                             ],
                             border: Border.all(color: Colors.grey.shade100),
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 children: [
                                   Container(
                                     width: 42,
                                     height: 42,
                                     decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       color: (rAvatar == null || rAvatar.isEmpty) 
                                           ? AppColors.primary2.withOpacity(0.1)
                                           : Colors.grey.shade200,
                                       image: (rAvatar != null && rAvatar.isNotEmpty)
                                         ? DecorationImage(
                                             image: NetworkImage(rAvatar), 
                                             fit: BoxFit.cover,
                                             onError: (_, __) {} // Prevent crash on invalid URL
                                           )
                                         : null,
                                     ),
                                     alignment: Alignment.center,
                                     child: (rAvatar == null || rAvatar.isEmpty)
                                       ? Text(
                                           rName.isNotEmpty ? rName.substring(0, 1).toUpperCase() : 'U',
                                           style: const TextStyle(
                                             color: AppColors.primary2, 
                                             fontWeight: FontWeight.bold,
                                             fontSize: 18
                                           ),
                                         )
                                       : null,
                                   ),
                                   const SizedBox(width: 12),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(
                                            rName.isNotEmpty ? rName : 'Anonymous', 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)
                                         ),
                                         const SizedBox(height: 4),
                                         Row(
                                          children: [
                                             ...List.generate(5, (i) => Icon(
                                               i < rVal ? Icons.star_rounded : Icons.star_outline_rounded,
                                               size: 14,
                                               color: AppColors.primary2,
                                             )),
                                             if (rDate != null) ...[
                                               const SizedBox(width: 8),
                                               Text(
                                                 _formatDate(rDate),
                                                 style: TextStyle(
                                                   color: Colors.grey.shade500,
                                                   fontSize: 11,
                                                   fontWeight: FontWeight.w500
                                                 ),
                                               ),
                                             ]
                                           ],
                                         )
                                       ],
                                     ),
                                   ),
                                 ],
                               ),
                               if (rReview != null && rReview.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.03), // Subtle blue tint instead of grey
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.08))
                                    ),
                                    child: Text(
                                      rReview,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        height: 1.5,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                               ]
                             ],
                           ),
                         );
                      }).toList(),
                    ],
                  ],
                );
              }
            ),
          ],
        );
      },
    );
  }

  Widget _fallbackBody(BuildContext context) {
      // Keeping fallback simple or could update similarly if needed
    final title = (data['title'] as String?) ?? 'Shop';
    final image = data['image'] as String?;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ... (Similar placeholder logic)
        // Since this is a fallback for testing without firebase doc, we can leave it or update it.
        // For now, I'll update at least the buttons.
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: image != null && image.isNotEmpty
                ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        Row(
          children: [
             Expanded(
               child: ElevatedButton.icon(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.deepOrange,
                   foregroundColor: Colors.white,
                 ),
                 onPressed: () {},
                 icon: const Icon(Icons.chat_bubble_outline),
                 label: const Text('Chat'),
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: ElevatedButton.icon(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.orange,
                   foregroundColor: Colors.white,
                 ),
                 onPressed: () => Navigator.pushNamed(context, AppRoutes.requestService),
                 icon: const Icon(Icons.assignment_turned_in_outlined),
                 label: const Text('Request'),
               ),
             ),
          ],
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey[300],
    child: const Center(child: Icon(Icons.image_not_supported)),
  );

  String _formatDate(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  Widget _servicePill(String label, String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _createOrOpenChat(
  String? shopId,
  String title,
  String? image,
) async {
  try {
    if (shopId == null) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final chatId = 'u_${uid}__s_${shopId}';
    final ref = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [uid, shopId],
        'title': title,
        'image': image,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  } catch (_) {
    return null;
  }
}

Future<void> _viewOnMap(double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> _launchMapUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Fallback or error handling
    debugPrint('Could not launch $url');
  }
}

class _FavoriteHeart extends StatelessWidget {
  final String shopId;
  const _FavoriteHeart({required this.shopId});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc.snapshots(),
      builder: (context, snap) {
        final favs =
            (snap.data?.data()?['favoriteShops'] as List?)?.cast<String>() ??
            const [];
        final isFav = favs.contains(shopId);
        return IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.orange : null,
          ),
          onPressed: () async {
            try {
              if (isFav) {
                await userDoc.update({
                  'favoriteShops': FieldValue.arrayRemove([shopId]),
                });
              } else {
                await userDoc.set({
                  'favoriteShops': FieldValue.arrayUnion([shopId]),
                }, SetOptions(merge: true));
              }
            } catch (_) {}
          },
        );
      },
    );
  }
}

class _ServicePill extends StatelessWidget {
  final String label;
  final String price;
  const _ServicePill({required this.label, required this.price});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
