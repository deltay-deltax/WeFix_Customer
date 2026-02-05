import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/shop_model.dart';
import '../core/constants/app_routes.dart';

class NearbyShopCard extends StatelessWidget {
  final NearbyShopModel shop;
  const NearbyShopCard({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final borderColor = shop.verified ? Colors.green.shade400 : Colors.blue.shade400;
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.shopDetails, arguments: shop);
      },
      child: Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image section maintains aspect ratio to avoid overflow
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
              children: [
                Positioned.fill(
                  child: (shop.imageAsset.startsWith('http'))
                      ? Image.network(
                          shop.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.image_not_supported)),
                          ),
                        )
                      : (shop.imageAsset.isNotEmpty)
                          ? Image.asset(
                              shop.imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.image_not_supported)),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.image)),
                            ),
                ),
                if (shop.verified)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          SizedBox(width: 4),
                          Icon(Icons.check, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  shop.location,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // View on Maps pill - always visible
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${shop.lat},${shop.lng}');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        shape: StadiumBorder(),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('View on Maps', style: TextStyle(fontSize: 12)),
                    ),
                    // Chat pill - only for verified
                    if (shop.verified)
                      TextButton.icon(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF1E40AF),
                          shape: StadiumBorder(),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.chat_bubble, size: 16),
                        label: const Text('Chat', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
