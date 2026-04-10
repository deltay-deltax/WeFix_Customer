import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';

/// Keywords used to classify a request as a heavy-appliance home-visit job.
/// These match the subcategories defined in search_screen.dart.
const Set<String> _kHeavyKeywords = {
  'fridge',
  'refrigerator',
  'washing machine',
  'air conditioner',
  ' ac ',
  'a.c',
  'smart tv',
  'led tv',
  'television',
  'tv',
  'water purifier',
  'ro system',
  'geyser',
  'water heater',
  'dishwasher',
  'chimney',
  'exhaust fan',
  'air cooler',
  'inverter',
};

bool _isHeavyAppliance(String deviceType) {
  final lower = ' ${deviceType.toLowerCase().trim()} ';
  return _kHeavyKeywords.any((kw) => lower.contains(kw));
}

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
  double? _pickupLat;
  double? _pickupLng;
  String priority = 'Low';
  bool loading = false;
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  List<String> _subcategories = [];
  bool _isLoadingSubcategories = true;
  String? _selectedDeviceType;

  @override
  void initState() {
    super.initState();
    _prefillUser();
    _fetchSubcategories();
  }

  Future<void> _fetchSubcategories() async {
    final shopId = widget.data['shopId'] as String?;
    if (shopId == null) {
      if (mounted) setState(() => _isLoadingSubcategories = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('registered_shop_users')
          .doc(shopId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final subs = data['subcategories'];
        if (subs is List) {
          setState(() {
            _subcategories = List<String>.from(subs);
            // If there's only one, or if we want to pre-select the first one
            if (_subcategories.isNotEmpty) {
              _selectedDeviceType = _subcategories.first;
              deviceTypeCtrl.text = _selectedDeviceType!;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSubcategories = false);
    }
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
            if (_isLoadingSubcategories)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              )
            else if (_subcategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedDeviceType,
                  decoration: InputDecoration(
                    labelText: 'Device Type',
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.primary2.withOpacity(.6),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary2,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: _subcategories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedDeviceType = newValue;
                      deviceTypeCtrl.text = newValue ?? '';
                    });
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Device Type is required' : null,
                ),
              )
            else
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
              hint: 'e.g., Apple, Samsung, Dell',
            ),
            _field(
              'Model Name', 
              modelNameCtrl, 
              style: _FieldStyle.blueOnFocus,
              hint: 'e.g., iPhone 13, Galaxy S21, Latitude 5420',
            ),
            _field(
              'Model Number',
              modelNumberCtrl,
              style: _FieldStyle.blueOnFocus,
              hint: 'e.g., A2633, SM-G991B',
            ),
            _field(
              'Problem',
              problemCtrl,
              required: true,
              style: _FieldStyle.blueOnFocus,
              hint: 'e.g., Screen cracked, Battery draining fast',
            ),
            _field(
              'Description',
              descriptionCtrl,
              maxLines: 3,
              style: _FieldStyle.blueOnFocus,
              hint: 'Provide more details about the issue...',
            ),
            _field(
              'Your Name', 
              yourNameCtrl, 
              style: _FieldStyle.blueOnFocus,
              hint: 'Your full name',
            ),
            _field(
              'Phone',
              phoneCtrl,
              keyboardType: TextInputType.phone,
              style: _FieldStyle.blueOnFocus,
              hint: 'Your contact number',
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  final selectedAddress = await Navigator.pushNamed(
                    context, 
                    AppRoutes.manageAddresses,
                    arguments: true, // isSelectionMode = true
                  );
                  if (selectedAddress != null && selectedAddress is Map) {
                    setState(() {
                      pickupCtrl.text = selectedAddress['address']?.toString() ?? '';
                      _pickupLat = double.tryParse(selectedAddress['lat']?.toString() ?? '');
                      _pickupLng = double.tryParse(selectedAddress['lng']?.toString() ?? '');
                    });
                  }
                },
                child: IgnorePointer(
                  child: _field(
                    'Pickup Address',
                    pickupCtrl,
                    maxLines: 3,
                    style: _FieldStyle.blueOnFocus,
                    hint: 'Select or type your pickup address',
                  ),
                ),
              ),
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
    String? hint,
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
          hintText: hint,
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
        'pickupLat': _pickupLat,
        'pickupLng': _pickupLng,
        'priority': priority,
        'images': imageUrls,
        'status': 'Pending',
        'isHeavyAppliance': _isHeavyAppliance(deviceTypeCtrl.text.trim()),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.requests,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
