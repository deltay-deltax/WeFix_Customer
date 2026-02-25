import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String userName;
  final String requestId;
  final String shopId;
  final String shopName;
  final String deviceType;
  final String category;
  final String title;
  final String description;
  final String status; // 'open' | 'in_review' | 'resolved'
  final DateTime? createdAt;

  ComplaintModel({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.requestId,
    required this.shopId,
    required this.shopName,
    required this.deviceType,
    required this.category,
    required this.title,
    required this.description,
    this.status = 'open',
    this.createdAt,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ComplaintModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      requestId: data['requestId'] ?? '',
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      deviceType: data['deviceType'] ?? '',
      category: data['category'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'requestId': requestId,
      'shopId': shopId,
      'shopName': shopName,
      'deviceType': deviceType,
      'category': category,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
