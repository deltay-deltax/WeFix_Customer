import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;

class LocationService {
  static Position? _lastPosition;
  static String? _lastAddress;

  Future<bool> ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    if (_lastPosition != null) return _lastPosition;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
    final ok = await ensurePermission();
    if (!ok) return null;
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );
      return _lastPosition;
    } catch (_) {
      // Fallback to high if bestForNavigation times out
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return _lastPosition;
    }
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    if (_lastAddress != null) return _lastAddress;
    final placemarks = await gc.placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;
    final sub = (p.subLocality ?? '').trim();
    final city = (p.locality ?? '').trim();
    if (sub.isNotEmpty && city.isNotEmpty) return _lastAddress = '$sub, $city';
    if (sub.isNotEmpty) return _lastAddress = sub;
    if (city.isNotEmpty) return _lastAddress = city;
    // Fallback to admin area only if both sub/city are empty
    final admin = (p.administrativeArea ?? '').trim();
    _lastAddress = admin.isNotEmpty ? admin : null;
    return _lastAddress;
  }

  /// Returns a structured map of location details once permission is granted.
  /// Fields: addressLine1, addressLine2, city, locality, state, country,
  /// pincode, latitude, longitude
  Future<Map<String, dynamic>?> getFullAddress() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;
    final placemarks = await gc.placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (placemarks.isEmpty) {
      return {'latitude': pos.latitude, 'longitude': pos.longitude};
    }
    final p = placemarks.first;
    // Compose address lines
    final line1Parts = [
      (p.name ?? '').trim(),
      (p.subThoroughfare ?? '').trim(),
      (p.thoroughfare ?? '').trim(),
    ].where((e) => e.isNotEmpty).toList();
    final line2Parts = [
      (p.subLocality ?? '').trim(),
      (p.locality ?? '').trim(),
    ].where((e) => e.isNotEmpty).toList();

    return {
      'addressLine1': line1Parts.join(', '),
      'addressLine2': line2Parts.join(', '),
      'city': (p.locality ?? '').trim(),
      'locality': (p.subLocality ?? '').trim(),
      'state': (p.administrativeArea ?? '').trim(),
      'country': (p.country ?? '').trim(),
      'pincode': (p.postalCode ?? '').trim(),
      'latitude': pos.latitude,
      'longitude': pos.longitude,
    };
  }
}
