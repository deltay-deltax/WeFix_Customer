import 'package:flutter/material.dart';
import '../data/models/shop_model.dart';
import '../core/services/location_service.dart';
import '../core/services/api_service.dart';

class NearbyShopsViewModel extends ChangeNotifier {
  final _location = LocationService();
  final _api = ApiService();
  bool loading = false;
  String? error;
  String query = '';

  List<NearbyShopModel> verified = [];
  List<NearbyShopModel> others = [];

  NearbyShopsViewModel() {
    fetch();
  }

  Future<void> fetch() async {
    loading = true; error = null; notifyListeners();
    try {
      final pos = await _location.getCurrentPosition();
      if (pos == null) {
        error = 'Location permission denied';
        return;
      }
      final results = await _api.getNearbyElectronics(lat: pos.latitude, lng: pos.longitude);
      final shops = results.map((r) => NearbyShopModel(
            r.name,
            r.address,
            r.photoRef != null ? _api.placePhotoUrl(r.photoRef!) : '',
            true,
            r.lat,
            r.lng,
          )).toList();
      // Split into verified and others (simple heuristic)
      verified = shops.take(6).toList();
      others = shops.skip(6).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false; notifyListeners();
    }
  }

  void setQuery(String q) {
    query = q.trim().toLowerCase();
    notifyListeners();
  }

  List<NearbyShopModel> get filteredVerified {
    if (query.isEmpty) return verified;
    return verified.where((s) => s.name.toLowerCase().contains(query) || s.location.toLowerCase().contains(query)).toList();
  }

  List<NearbyShopModel> get filteredOthers {
    if (query.isEmpty) return others;
    return others.where((s) => s.name.toLowerCase().contains(query) || s.location.toLowerCase().contains(query)).toList();
  }
}
