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
  final double? pickupLat;
  final double? pickupLng;
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
  final String? borzoOrderId;
  final String? borzoTrackingUrl;
  final String? borzoStatus;
  final String? borzoDeliveryCost;
  final bool? reverseDropScheduled;
  final String? reverseBorzoOrderId;
  final String? reverseBorzoTrackingUrl;
  final String? reverseBorzoStatus;

  // ── Home-visit flow (heavy appliances: Fridge, AC, Washer, TV) ──
  final bool? isHeavyAppliance;      // Set at creation time based on deviceType
  final DateTime? visitScheduledAt;  // Date+time the customer scheduled for technician visit
  final bool? visitConfirmedByUser;  // True once customer accepts amount & picks a slot

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
    this.pickupLat,
    this.pickupLng,
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
    this.borzoOrderId,
    this.borzoTrackingUrl,
    this.borzoStatus,
    this.borzoDeliveryCost,
    this.reverseDropScheduled,
    this.reverseBorzoOrderId,
    this.reverseBorzoTrackingUrl,
    this.reverseBorzoStatus,
    this.isHeavyAppliance,
    this.visitScheduledAt,
    this.visitConfirmedByUser,
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
      pickupLat: (data['pickupLat'] as num?)?.toDouble(),
      pickupLng: (data['pickupLng'] as num?)?.toDouble(),
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
      borzoOrderId: data['borzoOrderId']?.toString(),
      borzoTrackingUrl: data['borzoTrackingUrl']?.toString(),
      borzoStatus: data['borzoStatus']?.toString(),
      borzoDeliveryCost: data['borzoDeliveryCost']?.toString(),
      reverseDropScheduled: data['reverseDropScheduled'] as bool?,
      reverseBorzoOrderId: data['reverseBorzoOrderId']?.toString(),
      reverseBorzoTrackingUrl: data['reverseBorzoTrackingUrl']?.toString(),
      reverseBorzoStatus: data['reverseBorzoStatus']?.toString(),
      isHeavyAppliance: data['isHeavyAppliance'] as bool?,
      visitScheduledAt: (data['visitScheduledAt'] as Timestamp?)?.toDate(),
      visitConfirmedByUser: data['visitConfirmedByUser'] as bool?,
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
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
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
      'borzoOrderId': borzoOrderId,
      'borzoTrackingUrl': borzoTrackingUrl,
      'borzoStatus': borzoStatus,
      'borzoDeliveryCost': borzoDeliveryCost,
      'reverseDropScheduled': reverseDropScheduled,
      'reverseBorzoOrderId': reverseBorzoOrderId,
      'reverseBorzoTrackingUrl': reverseBorzoTrackingUrl,
      'reverseBorzoStatus': reverseBorzoStatus,
      'isHeavyAppliance': isHeavyAppliance,
      'visitScheduledAt': visitScheduledAt != null ? Timestamp.fromDate(visitScheduledAt!) : null,
      'visitConfirmedByUser': visitConfirmedByUser,
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

