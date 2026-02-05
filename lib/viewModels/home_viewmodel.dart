import 'package:flutter/material.dart';
import '../data/models/featured_shop_model.dart';
import '../core/services/location_service.dart';

class HomeViewModel extends ChangeNotifier {
  String pickupLocation = 'Fetching location...';
  final _location = LocationService();
  String query = '';
  final List<FeaturedShopModel> shops = [
    FeaturedShopModel(
      "Electro Gadgets",
      "Downtown, 1.2km",
      "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800",
    ),
    FeaturedShopModel(
      "Tech Zone",
      "Uptown, 2.5km",
      "https://images.unsplash.com/photo-1518770660439-4636190af475?w=800",
    ),
    FeaturedShopModel(
      "Digital World",
      "Midtown, 0.8km",
      "https://images.unsplash.com/photo-1518773553398-650c184e0bb3?w=800",
    ),
    FeaturedShopModel(
      "Gadget Hub",
      "Suburbia, 3.1km",
      "https://images.unsplash.com/photo-1521791136064-7986c2920216?w=800",
    ),
  ];

  HomeViewModel() {
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = await _location.getCurrentPosition();
    if (pos != null) {
      final addr = await _location.reverseGeocode(pos.latitude, pos.longitude);
      pickupLocation = addr ?? '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}';
      notifyListeners();
    } else {
      pickupLocation = 'Location permission required';
      notifyListeners();
    }
  }

  void setQuery(String q) {
    query = q.trim().toLowerCase();
    notifyListeners();
  }

  List<FeaturedShopModel> get filteredShops {
    if (query.isEmpty) return shops;
    return shops.where((s) => s.name.toLowerCase().contains(query) || s.location.toLowerCase().contains(query)).toList();
  }
}
