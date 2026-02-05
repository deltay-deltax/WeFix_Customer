import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';

enum _FieldStyle { orange, blueOnFocus }

class RequestServiceScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const RequestServiceScreen({super.key, required this.data});

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final formKey = GlobalKey<FormState>();
  final deviceTypeCtrl = TextEditingController();
  final brandCtrl = TextEditingController();
  final modelNameCtrl = TextEditingController();
  final modelNumberCtrl = TextEditingController();
  final problemCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final yourNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final pickupCtrl = TextEditingController();
  String priority = 'Low';
  bool loading = false;
  final _picker = ImagePicker();
  final List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    _prefillUser();
  }

  Widget _imagePickerRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images (max 4)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._images.map(
              (x) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(x.path),
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () => setState(() => _images.remove(x)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_images.length < 4)
              InkWell(
                onTap: _pickImages,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary2.withOpacity(.3),
                    ),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final res = await _picker.pickMultiImage();
    if (res.isEmpty) return;
    setState(() {
      final space = 4 - _images.length;
      _images.addAll(res.take(space));
    });
  }

  Future<void> _prefillUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final d = snap.data();
      if (d != null) {
        // Robust fallback for name
        final name = (d['name'] ?? d['Name'] ?? d['userName'] ?? d['username'] ?? '').toString();
        final phone = (d['phone'] ?? '').toString();
        
        if (name.isNotEmpty) yourNameCtrl.text = name;
        if (phone.isNotEmpty) phoneCtrl.text = phone;
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    deviceTypeCtrl.dispose();
    brandCtrl.dispose();
    modelNameCtrl.dispose();
    modelNumberCtrl.dispose();
    problemCtrl.dispose();
    descriptionCtrl.dispose();
    yourNameCtrl.dispose();
    phoneCtrl.dispose();
    pickupCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopId = widget.data['shopId'] as String?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Service'),
        backgroundColor: AppColors.primary2,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              'Device Type',
              deviceTypeCtrl,
              required: true,
              style: _FieldStyle.orange,
            ),
            _field(
              'Brand',
              brandCtrl,
              required: true,
              style: _FieldStyle.blueOnFocus,
            ),
            _field('Model Name', modelNameCtrl, style: _FieldStyle.blueOnFocus),
            _field(
              'Model Number',
              modelNumberCtrl,
              style: _FieldStyle.blueOnFocus,
            ),
            _field(
              'Problem',
              problemCtrl,
              required: true,
              style: _FieldStyle.blueOnFocus,
            ),
            _field(
              'Description',
              descriptionCtrl,
              maxLines: 3,
              style: _FieldStyle.blueOnFocus,
            ),
            _field('Your Name', yourNameCtrl, style: _FieldStyle.blueOnFocus),
            _field(
              'Phone',
              phoneCtrl,
              keyboardType: TextInputType.phone,
              style: _FieldStyle.blueOnFocus,
            ),
            _field(
              'Pickup Address',
              pickupCtrl,
              maxLines: 3,
              style: _FieldStyle.blueOnFocus,
            ),
            const SizedBox(height: 8),
            const Text(
              'Priority',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Low', 'Medium', 'High', 'Urgent'].map((p) {
                final selected = priority == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: selected,
                  selectedColor: AppColors.primary2.withOpacity(.15),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary2 : Colors.black87,
                  ),
                  side: selected
                      ? BorderSide(color: AppColors.primary2, width: 1.5)
                      : const BorderSide(color: Colors.transparent),
                  onSelected: (_) => setState(() => priority = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _imagePickerRow(),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : () => _submit(shopId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary2,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    _FieldStyle style = _FieldStyle.blueOnFocus,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: style == _FieldStyle.orange
                  ? AppColors.primary2
                  : Colors.transparent,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: style == _FieldStyle.orange
                  ? AppColors.primary2.withOpacity(.6)
                  : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: style == _FieldStyle.orange
                  ? AppColors.primary2
                  : AppColors.primary,
              width: 1.5,
            ),
          ),
          isDense: true,
        ),
      ),
    );
  }

  Future<void> _submit(String? shopId) async {
    if (shopId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing shop id')));
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final shopDoc =
          FirebaseFirestore.instance.collection('shop_users').doc(shopId);
      final shopSnap = await shopDoc.get();
      final shopName =
          (shopSnap.data()?['companyLegalName'] ?? 'Shop').toString();
      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        final storage = FirebaseStorage.instance;
        for (final x in _images) {
          final ref = storage.ref().child(
                'requests/${DateTime.now().millisecondsSinceEpoch}_${x.name}',
              );
          await ref.putFile(File(x.path));
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }
      await shopDoc.collection('requests').add({
        'userId': uid,
        'shopId': shopId,
        'shopName': shopName,
        'deviceType': deviceTypeCtrl.text.trim(),
        'brand': brandCtrl.text.trim(),
        'modelName': modelNameCtrl.text.trim(),
        'modelNumber': modelNumberCtrl.text.trim(),
        'problem': problemCtrl.text.trim(),
        'description': descriptionCtrl.text.trim(),
        'yourName': yourNameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'pickupAddress': pickupCtrl.text.trim(),
        'priority': priority,
        'images': imageUrls,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request submitted')));
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.requests,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
