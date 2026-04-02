import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../viewModels/profile_viewmodel.dart';

class ManageAddressesScreen extends StatefulWidget {
  final bool isSelectionMode;
  const ManageAddressesScreen({Key? key, this.isSelectionMode = false}) : super(key: key);

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  
  Widget _buildAddressCard({
    required String title,
    required String fullAddress,
    required IconData icon,
    bool isCurrentLocation = false,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrentLocation ? Colors.blue.withOpacity(0.1) : AppColors.primary2.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isCurrentLocation ? Colors.blue : AppColors.primary2, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                         if (onDelete != null)
                           InkWell(
                             onTap: onDelete,
                             child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                           ),
                       ],
                     ),
                     const SizedBox(height: 6),
                     Text(
                       fullAddress,
                       style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                     ),
                     if (widget.isSelectionMode) ...[
                       const SizedBox(height: 12),
                       Text(
                         'TAP TO SELECT',
                         style: TextStyle(
                           color: isCurrentLocation ? Colors.blue : AppColors.primary2,
                           fontSize: 11,
                           fontWeight: FontWeight.bold,
                         ),
                       )
                     ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('addresses')
                    .doc(docId)
                    .delete();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only wrap with ChangeNotifierProvider if we aren't already wrapped by one from ProfileScreen
    // Since we navigate potentially from RequestServiceScreen, we wrap it here locally to safely fetch GPS.
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isSelectionMode ? 'Select Address' : 'My Addresses'),
          backgroundColor: AppColors.primary2,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('CURRENT GPS LOCATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Consumer<ProfileViewModel>(
                      builder: (context, vm, _) {
                        if (vm.currentLocation == null) {
                           return const Card(
                             child: Padding(
                               padding: EdgeInsets.all(16.0),
                               child: Center(child: CircularProgressIndicator()),
                             )
                           );
                        }
                        
                        return _buildAddressCard(
                          title: 'Current Location',
                          fullAddress: vm.currentLocation!,
                          icon: Icons.my_location,
                          isCurrentLocation: true,
                          onTap: widget.isSelectionMode ? () {
                            Navigator.pop(context, {
                              'address': vm.currentLocation,
                              'lat': vm.currentLat,
                              'lng': vm.currentLng,
                            });
                          } : null,
                        );
                      }
                    ),
                    const SizedBox(height: 24),
                    const Text('SAVED ADDRESSES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseAuth.instance.currentUser != null ? 
                         FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('addresses')
                          .orderBy('createdAt', descending: true)
                          .snapshots()
                        : const Stream.empty(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                        }
                        
                        final docs = snapshot.data?.docs ?? [];
                        
                        if (docs.isEmpty) {
                           return Container(
                             padding: const EdgeInsets.all(24),
                             alignment: Alignment.center,
                             child: Column(
                               children: [
                                 Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                                 const SizedBox(height: 12),
                                 Text('No saved addresses found.', style: TextStyle(color: Colors.grey.shade600))
                               ],
                             ),
                           );
                        }
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            final String title = data['title'] ?? 'Other';
                            
                            // Build nicely formatted full address string
                            List<String> parts = [];
                            if (data['addressLine1'] != null && data['addressLine1'].toString().isNotEmpty) parts.add(data['addressLine1']);
                            if (data['addressLine2'] != null && data['addressLine2'].toString().isNotEmpty) parts.add(data['addressLine2']);
                            if (data['city'] != null && data['city'].toString().isNotEmpty) parts.add(data['city']);
                            if (data['state'] != null && data['state'].toString().isNotEmpty) parts.add(data['state']);
                            if (data['pincode'] != null && data['pincode'].toString().isNotEmpty) parts.add(data['pincode']);
                            
                            final fullAddress = parts.join(', ');
                            
                            return _buildAddressCard(
                              title: title,
                              fullAddress: fullAddress,
                              icon: Icons.home_outlined,
                              onDelete: () => _confirmDelete(docs[i].id),
                              onTap: widget.isSelectionMode ? () {
                                Navigator.pop(context, {
                                  'address': fullAddress,
                                  'lat': data['lat'],
                                  'lng': data['lng'],
                                });
                              } : null,
                            );
                          },
                        );
                      }
                    )
                  ],
                ),
              ),
              
              // Bottom button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.addAddress);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add new address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary2,
                      side: const BorderSide(color: AppColors.primary2, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
