import 'package:flutter/material.dart';
import '../data/models/service_request_model.dart';

class ServiceUpdateViewModel extends ChangeNotifier {
  final List<ServiceRequestModel> requests = [
    ServiceRequestModel(
      amount: "85.00",
      brand: "LG",
      createdAt: DateTime.parse("2023-10-15"),
      description: "Screen flickering issue",
      deviceType: "LGOS23",
      images: [],
      modelName: "OS23",
      modelNumber: "LG-123",
      phone: "1234567890",
      pickupAddress: "123 Main St",
      priority: "High",
      problem: "Screen Flickering",
      shopId: "shop1",
      shopName: "FixIt Shop",
      status: "in_progress",
      updatedAt: DateTime.parse("2023-10-15"),
      userId: "user1",
      yourName: "John Doe",
    ),
    ServiceRequestModel(
      amount: "150.00",
      brand: "Apple",
      createdAt: DateTime.parse("2023-10-14"),
      description: "Won't turn on",
      deviceType: "IP 320",
      images: [],
      modelName: "320",
      modelNumber: "IP-320",
      phone: "0987654321",
      pickupAddress: "456 Elm St",
      priority: "Medium",
      problem: "Won't turn on",
      shopId: "shop2",
      shopName: "TechCare",
      status: "pending",
      updatedAt: DateTime.parse("2023-10-14"),
      userId: "user2",
      yourName: "Jane Smith",
    ),
  ];
}
