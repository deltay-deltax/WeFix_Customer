import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/constants/app_colors.dart';
import '../core/constants/api_keys.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({Key? key}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _line2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  
  double? _lat;
  double? _lng;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _addressSelected = false;
  List<dynamic> _predictions = [];
  Timer? _debounce;
  String _selectedType = 'Home';

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = 'Home';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      try {
        final url = Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=${ApiKeys.googleMapsKey}&components=country:in');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && mounted) {
            setState(() {
              _predictions = data['predictions'] ?? [];
              _isSearching = false;
            });
          } else {
            if (mounted) {
              setState(() => _isSearching = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Maps Error: ${data["status"]} - ${data["error_message"] ?? "Unknown"}')));
            }
          }
        }
      } catch (e) {
        if (mounted) {
           setState(() => _isSearching = false);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network Error: \$e')));
        }
      }
    });
  }

  Future<void> _selectPrediction(dynamic item) async {
    final placeId = item['place_id'];
    setState(() {
      _searchCtrl.text = item['description'] ?? '';
      _predictions = [];
      _isSearching = true; // Show loading while fetching details
    });
    FocusScope.of(context).unfocus();

    try {
      final url = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${ApiKeys.googleMapsKey}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          
          if (mounted) {
            setState(() {
              _lat = result['geometry']?['location']?['lat'];
              _lng = result['geometry']?['location']?['lng'];
              _addressSelected = true;
              _isSearching = false;
              
              _line2Ctrl.text = item['description'] ?? '';
              
              if (result['address_components'] != null) {
                final components = result['address_components'] as List;
                for (var component in components) {
                  final types = component['types'] as List;
                  if (types.contains('locality') || types.contains('administrative_area_level_2')) {
                    _cityCtrl.text = component['long_name'];
                  }
                  if (types.contains('administrative_area_level_1')) {
                    _stateCtrl.text = component['long_name'];
                  }
                  if (types.contains('postal_code')) {
                    _pincodeCtrl.text = component['long_name'];
                  }
                }
              }
            });
          }
        } else {
          if (mounted) setState(() => _isSearching = false);
        }
      }
    } catch (e) {
       if (mounted) setState(() => _isSearching = false);
    }
  }



  Future<void> _saveAddress() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .add({
        'title': _titleCtrl.text.trim(),
        'addressLine1': _line1Ctrl.text.trim(),
        'addressLine2': _line2Ctrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        if (_lat != null) 'lat': _lat,
        if (_lng != null) 'lng': _lng,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully!')),
      );
      Navigator.pop(context); // Return back to manage addresses
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: \$e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPill(String type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (type != 'Other') {
            _titleCtrl.text = type;
            FocusScope.of(context).unfocus();
          } else {
            _titleCtrl.text = ''; 
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(type, style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade800,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool required = true, TextInputType? keyboardType, void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Please enter \$label' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Address'),
        backgroundColor: AppColors.primary2,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Search Map Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildField('Search building, area or landmark', _searchCtrl, required: false, onChanged: _onSearchChanged),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              if (_predictions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _predictions.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = _predictions[i];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.grey),
                        title: Text(item['description'] ?? '', style: const TextStyle(fontSize: 13)),
                        onTap: () => _selectPrediction(item),
                      );
                    },
                  ),
                ),
              if (_lat != null && _lng != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Location Selected', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              
              if (_addressSelected) ...[
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Enter Address Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Save Address As', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPill('Home', Icons.home_outlined),
                    _buildPill('Work', Icons.work_outline),
                    _buildPill('Other', Icons.location_on_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedType == 'Other')
                  _buildField('Custom Label (e.g. Gym, Friend)', _titleCtrl),
              _buildField('Flat / House No / Building', _line1Ctrl),
              _buildField('Street / Area / Locality', _line2Ctrl),
              Row(
                children: [
                   Expanded(child: _buildField('City', _cityCtrl)),
                   const SizedBox(width: 12),
                   Expanded(child: _buildField('Pincode', _pincodeCtrl, keyboardType: TextInputType.number)),
                ],
              ),
              _buildField('State', _stateCtrl),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary2,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
