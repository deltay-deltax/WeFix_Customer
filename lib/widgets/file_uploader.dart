import 'package:flutter/material.dart';

class FileUploader extends StatelessWidget {
  final Function(String path) onFilePicked;
  FileUploader({required this.onFilePicked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Simulate picker. Plug into real file picker for production
        onFilePicked('dummy_receipt_path.pdf');
      },
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[100],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 40, color: Colors.grey[600]),
            SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: "Upload a "),
                  TextSpan(
                    text: "file",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: " or drag and drop"),
                ],
              ),
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 8),
            Text(
              "PNG, JPG, PDF up to 10MB",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
