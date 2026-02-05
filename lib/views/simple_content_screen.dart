import 'package:flutter/material.dart';

class SimpleContentScreen extends StatelessWidget {
  final String title;
  final String content;

  const SimpleContentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          content,
          style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
        ),
      ),
    );
  }
}
