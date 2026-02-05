import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequestModel {
  final String id;
  final String amount;
  final String brand;
  final DateTime? createdAt;
  final String description;
  final String deviceType;
  final List<String> images;
  final String modelName;
  final String modelNumber;
  final String phone;
  final String pickupAddress;
  final String priority;
  final String problem;
  final String shopId;
  final String shopName;
  final String status;
  final DateTime? updatedAt;
  final String userId;
  final String yourName;
  final ServiceDetails? serviceDetails;
  final DocumentReference? reference;
  final int? rating;
  final String? review;

  ServiceRequestModel({
     this.id = '',
    required this.amount,
    required this.brand,
    this.createdAt,
    required this.description,
    required this.deviceType,
    required this.images,
    required this.modelName,
    required this.modelNumber,
    required this.phone,
    required this.pickupAddress,
    required this.priority,
    required this.problem,
    required this.shopId,
    required this.shopName,
    required this.status,
    this.updatedAt,
    required this.userId,
    required this.yourName,

    this.serviceDetails,
    this.reference,
    this.rating,
    this.review,
  });

  factory ServiceRequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ServiceRequestModel(
      id: doc.id,
      reference: doc.reference,
      amount: data['amount'] ?? '',
      brand: data['brand'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      description: data['description'] ?? '',
      deviceType: data['deviceType'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      modelName: data['modelName'] ?? '',
      modelNumber: data['modelNumber'] ?? '',
      phone: data['phone'] ?? '',
      pickupAddress: data['pickupAddress'] ?? '',
      priority: data['priority'] ?? '',
      problem: data['problem'] ?? '',
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      status: data['status'] ?? 'waiting_for_confirmation',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      userId: data['userId'] ?? '',
      yourName: data['yourName'] ?? '',
      serviceDetails: data['serviceDetails'] != null
          ? ServiceDetails.fromMap(data['serviceDetails'] as Map<String, dynamic>)
          : null,
      rating: data['rating'] is int ? data['rating'] : null,
      review: data['review'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'brand': brand,
      'createdAt': createdAt,
      'description': description,
      'deviceType': deviceType,
      'images': images,
      'modelName': modelName,
      'modelNumber': modelNumber,
      'phone': phone,
      'pickupAddress': pickupAddress,
      'priority': priority,
      'problem': problem,
      'shopId': shopId,
      'shopName': shopName,
      'status': status,
      'updatedAt': updatedAt,
      'userId': userId,
      'yourName': yourName,
      'serviceDetails': serviceDetails?.toMap(),
      'rating': rating,
      'review': review,
    };
  }
}

class ServiceDetails {
  final num laborCost;
  final num partsCost;
  final String partsReplaced;
  final String description; // Maps to 'serviceDetails' string in JSON
  final num totalCost;
  final String warranty;
  final DateTime? lastUpdated;

  ServiceDetails({
    required this.laborCost,
    required this.partsCost,
    required this.partsReplaced,
    required this.description,
    required this.totalCost,
    required this.warranty,
    this.lastUpdated,
  });

  factory ServiceDetails.fromMap(Map<String, dynamic> map) {
    return ServiceDetails(
      laborCost: map['laborCost'] ?? 0,
      partsCost: map['partsCost'] ?? 0,
      partsReplaced: map['partsReplaced'] ?? '',
      description: map['serviceDetails'] ?? '', // Note field name mapping
      totalCost: map['totalCost'] ?? 0,
      warranty: map['warranty'] ?? 'Na',
      // Parse lastUpdated string "2026-02-04T..." or Timestamp
      lastUpdated: map['lastUpdated'] is Timestamp
          ? (map['lastUpdated'] as Timestamp).toDate()
          : map['lastUpdated'] is String
              ? DateTime.tryParse(map['lastUpdated'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'laborCost': laborCost,
      'partsCost': partsCost,
      'partsReplaced': partsReplaced,
      'serviceDetails': description,
      'totalCost': totalCost,
      'warranty': warranty,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}

