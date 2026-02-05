import 'package:flutter/material.dart';
import '../data/models/shop_model.dart';
import '../core/constants/app_colors.dart';

class ShopDetailsScreen extends StatelessWidget {
  final Object? args;
  const ShopDetailsScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final shop = (args is NearbyShopModel) ? args as NearbyShopModel : ModalRoute.of(context)!.settings.arguments as NearbyShopModel;
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                shop.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            shop.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(shop.location, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),

          // Services and charges (dummy)
          Text('Services & Charges', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _PricePill(label: 'Battery Replacement', price: '₹4000'),
              _PricePill(label: 'Charging Port Repair', price: '₹700'),
              _PricePill(label: 'Speaker Repair', price: '₹600'),
              _PricePill(label: 'Software Update', price: '₹300'),
            ],
          ),
          const SizedBox(height: 18),

          // Request Service card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  _TextField(hint: 'Device Type (e.g., Phone)'),
                  const SizedBox(height: 8),
                  _TextField(hint: 'Brand (e.g., Apple, Samsung)'),
                  const SizedBox(height: 8),
                  _TextField(hint: 'Model Name'),
                  const SizedBox(height: 8),
                  _TextField(hint: 'Problem', maxLines: 2),
                  const SizedBox(height: 8),
                  _TextField(hint: 'Description', maxLines: 3),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _TextField(hint: 'Your Name')),
                      const SizedBox(width: 8),
                      Expanded(child: _TextField(hint: 'Phone')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _TextField(hint: 'Pickup Address'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted')));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                      child: const Text('Submit Request'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String label;
  final String price;
  const _PricePill({required this.label, required this.price});
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
          Text(price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String hint;
  final int maxLines;
  const _TextField({required this.hint, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    );
  }
}
