import 'package:flutter/material.dart';

class WarrantyViewModel extends ChangeNotifier {
  String? modelName;
  String? modelNumber;
  DateTime? purchaseDate;
  String? company;
  String? email;
  String? phone;
  String? receiptPath;

  void setPurchaseDate(DateTime date) {
    purchaseDate = date;
    notifyListeners();
  }

  void setReceipt(String path) {
    receiptPath = path;
    notifyListeners();
  }
}
