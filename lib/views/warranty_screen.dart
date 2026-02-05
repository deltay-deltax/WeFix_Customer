import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/app_colors.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelName = TextEditingController();
  final _modelNumber = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _warrantyValidity = '1 Year'; // Default value
  DateTime? _purchaseDate;
  XFile? _receipt;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _modelName.dispose();
    _modelNumber.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Warranty'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/warranty-history'),
            tooltip: 'Warranty History',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field('Model Name', _modelName, required: true),
                _field('Model Number', _modelNumber),
                _dateField(),
                const SizedBox(height: 12),
                _validityField(),
                const SizedBox(height: 12),
                _field('Company', _company, required: true),
                _field(
                  'Email Address (for warranty notifications)',
                  _email,
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(
                  'Phone Number (for SMS notifications)',
                  _phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                Text(
                  'Receipt (optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: _pickReceipt,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(.3),
                          ),
                        ),
                        child: _receipt == null
                            ? const Icon(Icons.receipt_long_outlined)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_receipt!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add Warranty',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Warranty',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Warranty History',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          _historyList(),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
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
            borderSide: BorderSide(color: AppColors.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(.45)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickDate,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Purchase Date',
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(.45)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            isDense: true,
          ),
          child: Text(
            _purchaseDate == null
                ? 'Select date'
                : _purchaseDate!.toLocal().toString().split(' ').first,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (res != null) setState(() => _purchaseDate = res);
  }

  Future<void> _pickReceipt() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _receipt = x);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login required')));
        return;
      }
      String? receiptUrl;
      if (_receipt != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'warranties/${uid}_${DateTime.now().millisecondsSinceEpoch}_${_receipt!.name}',
        );
        await ref.putFile(File(_receipt!.path));
        receiptUrl = await ref.getDownloadURL();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('warranties')
          .add({
            'modelName': _modelName.text.trim(),
            'modelNumber': _modelNumber.text.trim(),
            'purchaseDate': _purchaseDate,
            'company': _company.text.trim(),
            'email': _email.text.trim(),
            'phone': _phone.text.trim(),
            'receiptUrl': receiptUrl,
            'warrantyValidity': _warrantyValidity,
            'createdAt': FieldValue.serverTimestamp(),
          });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Warranty saved')));
      _formKey.currentState?.reset();
      setState(() {
        _purchaseDate = null;
        _receipt = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _historyList() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Login to see your warranty history'),
      );
    }
    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('warranties')
        .orderBy('createdAt', descending: true);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No warranties yet'),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, i) {
            final d = docs[i].data();
            final date = (d['purchaseDate'] as Timestamp?)?.toDate();
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.verified_user)),
              title: Text(
                (d['modelName'] ?? 'Unknown').toString(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  if (d['company'] != null &&
                      d['company'].toString().isNotEmpty)
                    d['company'],
                  if (d['modelNumber'] != null &&
                      d['modelNumber'].toString().isNotEmpty)
                    'Model: ${d['modelNumber']}',
                  if (date != null)
                    'Purchased: ${date.toLocal().toString().split(' ').first}',
                  if (d['warrantyValidity'] != null)
                     'Valid for: ${d['warrantyValidity']}',
                ].join('  •  '),
              ),
              trailing: d['receiptUrl'] != null
                  ? IconButton(
                      icon: const Icon(Icons.receipt_long),
                      onPressed: () {
                        // Could open full-screen viewer; for now just snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Receipt attached')),
                        );
                      },
                    )
                  : null,
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemCount: docs.length,
        );
      },
    );
  }
  Widget _validityField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Warranty Validity',
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(.45)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _warrantyValidity,
          isExpanded: true,
          onChanged: (v) {
            if (v != null) setState(() => _warrantyValidity = v);
          },
          items:
              [
                '1 Month',
                '3 Months',
                '6 Months',
                '1 Year',
                '2 Years',
                '3 Years',
                '5 Years',
                'Lifetime',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }
}
