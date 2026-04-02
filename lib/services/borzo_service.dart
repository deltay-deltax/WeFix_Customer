import 'package:cloud_functions/cloud_functions.dart';

class BorzoService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Calculates the delivery cost using Borzo API
  Future<Map<String, dynamic>> calculateOrder({
    required String userAddress,
    double? userLat,
    double? userLng,
    required String userName,
    required String userPhone,
    required String shopAddress,
    double? shopLat,
    double? shopLng,
    required String shopName,
    required String shopPhone,
    String type = 'standard', // 'standard' or 'endofday'
  }) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('calculateBorzoOrder');

      final Map<String, dynamic> userPoint = {
        'address': userAddress,
        'note': 'Exact Address: $userAddress',
        'contact_person': {
          'name': userName,
          'phone': userPhone,
        },
      };
      if (userLat != null && userLng != null) {
        userPoint['latitude'] = userLat;
        userPoint['longitude'] = userLng;
      }

      final Map<String, dynamic> shopPoint = {
        'address': shopAddress,
        'note': 'Exact Address: $shopAddress',
        'contact_person': {
          'name': shopName,
          'phone': shopPhone,
        },
      };
      if (shopLat != null && shopLng != null) {
        shopPoint['latitude'] = shopLat;
        shopPoint['longitude'] = shopLng;
      }

      final response = await callable.call(<String, dynamic>{
        'type': type,
        'points': [userPoint, shopPoint]
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to calculate Borzo delivery cost: $e');
    }
  }

  /// Creates a Borzo delivery order
  Future<Map<String, dynamic>> createOrder({
    required String userAddress,
    double? userLat,
    double? userLng,
    required String userName,
    required String userPhone,
    required String shopAddress,
    double? shopLat,
    double? shopLng,
    required String shopName,
    required String shopPhone,
    required String requestId,
    required String shopId,
    String? requiredStartDatetime,
    String? requiredFinishDatetime,
    String type = 'standard',
  }) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('createBorzoOrder');

      final userPoint = <String, dynamic>{
        'address': userAddress,
        'note': 'Exact Address: $userAddress',
        'contact_person': {
          'name': userName,
          'phone': userPhone,
        },
      };

      if (userLat != null && userLng != null) {
        userPoint['latitude'] = userLat;
        userPoint['longitude'] = userLng;
      }
      if (requiredStartDatetime != null) {
        userPoint['required_start_datetime'] = requiredStartDatetime;
      }
      if (requiredFinishDatetime != null) {
        userPoint['required_finish_datetime'] = requiredFinishDatetime;
      }

      final shopPoint = <String, dynamic>{
        'address': shopAddress,
        'note': 'Exact Address: $shopAddress',
        'contact_person': {
          'name': shopName,
          'phone': shopPhone,
        },
      };
      if (shopLat != null && shopLng != null) {
        shopPoint['latitude'] = shopLat;
        shopPoint['longitude'] = shopLng;
      }

      final response = await callable.call(<String, dynamic>{
        'type': type,
        'requestId': requestId,
        'shopId': shopId,
        'points': [userPoint, shopPoint]
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to create Borzo order: $e');
    }
  }
}
