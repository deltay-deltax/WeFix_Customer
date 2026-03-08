import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/shop_image_helper.dart';

class ShopAsyncImage extends StatelessWidget {
  final String shopId;
  final BoxFit fit;
  final Widget Function(BuildContext, Object?, StackTrace?) errorBuilder;

  const ShopAsyncImage({
    Key? key,
    required this.shopId,
    this.fit = BoxFit.cover,
    required this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('registered_shop_users')
          .doc(shopId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return errorBuilder(
              context,
              Exception('Shop document not found in registered_shop_users'),
              null);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final imageUrl = ShopImageHelper.getImage(data);

        if (imageUrl == null || imageUrl.isEmpty) {
          return errorBuilder(
              context,
              Exception('No valid image found in registered_shop_users data'),
              null);
        }

        return Image.network(
          imageUrl,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
