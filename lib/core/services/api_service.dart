import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/key.dart';

class PlacesResult {
  final String name;
  final String address;
  final String? photoRef;
  final double lat;
  final double lng;
  PlacesResult({required this.name, required this.address, this.photoRef, required this.lat, required this.lng});
}

class ApiService {
  static const _basePlaces = 'https://maps.googleapis.com/maps/api/place';

  String placePhotoUrl(String photoRef, {int maxWidth = 400}) {
    return '$_basePlaces/photo?maxwidth=$maxWidth&photo_reference=$photoRef&key=${ApiKeys.googleMaps}';
  }

  Future<List<PlacesResult>> getNearbyElectronics({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
  }) async {
    final uri = Uri.parse(
        '$_basePlaces/nearbysearch/json?location=$lat,$lng&radius=$radiusMeters&type=electronics_store&key=${ApiKeys.googleMaps}');
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = json.decode(res.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? [];
    return results.map((e) {
      final name = e['name'] as String? ?? 'Unknown';
      final address = e['vicinity'] as String? ?? '';
      final photos = e['photos'] as List?;
      final photoRef = photos != null && photos.isNotEmpty ? photos.first['photo_reference'] as String? : null;
      final geometry = e['geometry'] as Map<String, dynamic>?;
      final loc = geometry != null ? geometry['location'] as Map<String, dynamic>? : null;
      final lat = (loc?['lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (loc?['lng'] as num?)?.toDouble() ?? 0.0;
      return PlacesResult(name: name, address: address, photoRef: photoRef, lat: lat, lng: lng);
    }).toList();
  }
}
