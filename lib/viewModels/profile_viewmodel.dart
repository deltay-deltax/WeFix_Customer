import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/models/favorite_shop_model.dart';
import '../core/services/location_service.dart';

class ProfileViewModel extends ChangeNotifier {
  String name = "";
  String email = "";
  String? photoUrl;
  final List<FavoriteShopModel> favoriteShops = [
    FavoriteShopModel(
      "Fresh Mart",
      "Downtown, 1.2km",
      "assets/images/shop1.png",
    ),
    FavoriteShopModel(
      "The Corner Bakery",
      "Uptown, 2.5km",
      "assets/images/shop2.png",
    ),
    FavoriteShopModel(
      "City Pharmacy",
      "Midtown, 0.8km",
      "assets/images/shop3.png",
    ),
    FavoriteShopModel(
      "Pet Paradise",
      "Suburbia, 3.1km",
      "assets/images/shop4.png",
    ),
  ];

  String? currentLocation;
  final _loc = LocationService();
  Map<String, dynamic>? fullAddress;
  final _picker = ImagePicker();

  ProfileViewModel() {
    initUser();
    _initLocation();
  }

  String phone = "";

  Future<void> initUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        email = user.email ?? "";
        photoUrl = user.photoURL;
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final d = snap.data();
        if (d != null) {
          name = (d['Name'] ?? d['name'] ?? d['userName'] ?? d['username'] ?? name).toString();
          phone = (d['phone'] ?? phone).toString();
          photoUrl = (d['photoUrl'] ?? photoUrl)?.toString();
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _initLocation() async {
    final ok = await _loc.ensurePermission();
    if (!ok) {
      currentLocation = 'Location permission required';
      notifyListeners();
      return;
    }
    final pos = await _loc.getCurrentPosition();
    if (pos != null) {
      currentLocation = await _loc.reverseGeocode(pos.latitude, pos.longitude);
      fullAddress = await _loc.getFullAddress();
      notifyListeners();
    }
  }

  Future<void> updateProfile(String newName, String newPhone) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': newName,
        'phone': newPhone,
      }, SetOptions(merge: true));

      name = newName;
      phone = newPhone;
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating profile: $e");
    }
  }

  Future<void> changeAvatar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      final ref = FirebaseStorage.instance.ref().child(
        'users/${user.uid}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putData(await picked.readAsBytes());
      final url = await ref.getDownloadURL();
      photoUrl = url;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': url,
        'email': user.email,
      }, SetOptions(merge: true));
      await user.updatePhotoURL(url);
      notifyListeners();
    } catch (_) {}
  }
}
