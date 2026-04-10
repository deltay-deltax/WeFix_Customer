import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/models/service_request_model.dart';
import '../core/constants/app_colors.dart';
import '../widgets/full_screen_image_viewer.dart';
import 'raise_complaint_screen.dart';
import '../services/pdf_invoice_service.dart';

class ServiceRequestDetailScreen extends StatefulWidget {
  final ServiceRequestModel request;

  const ServiceRequestDetailScreen({super.key, required this.request});

  @override
  State<ServiceRequestDetailScreen> createState() =>
      _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState
    extends State<ServiceRequestDetailScreen> {
  int _pendingRating = 0;
  final TextEditingController _reviewCtrl = TextEditingController();
  final TextEditingController _couponCtrl = TextEditingController();
  bool _hideRating = false;
  bool _isSubmitting = false;
  bool _isApplyingCoupon = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(ServiceRequestModel req) async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingCoupon = true);
    try {
      final couponSnap = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .get();

      if (couponSnap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired coupon code'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final couponData = couponSnap.docs.first.data();
      final num discount = couponData['discountAmount'] ?? 0;
      final String type = couponData['type'] ?? 'fixed';

      num finalDiscount = 0;
      if (type == 'percentage') {
        finalDiscount = (req.serviceDetails!.totalCost * discount) / 100;
      } else {
        finalDiscount = discount;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('shop_users')
          .doc(req.shopId)
          .collection('requests')
          .doc(req.id)
          .update({
        'appliedCoupon': code,
        'discountAmount': finalDiscount,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon applied! You saved ₹$finalDiscount'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying coupon: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplyingCoupon = false);
    }
  }

  Future<void> _submitRating(ServiceRequestModel req) async {
    if (_pendingRating == 0) return;

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'Anonymous';
      final userId = user?.uid;
      final userAvatar = user?.photoURL;

      final review = _reviewCtrl.text.trim();

      // 1. Update the Request document (Correct Path)
      // Force path to shop_users/{shopId}/requests/{id} to avoid any root /requests reference issues
      final requestRef = FirebaseFirestore.instance
          .collection('shop_users')
          .doc(req.shopId)
          .collection('requests')
          .doc(req.id);

      // Check if doc exists before updating to avoid crash, though it should exist
      final docSnap = await requestRef.get();
      if (!docSnap.exists) {
        throw Exception(
            "Service request document not found at expected path: ${requestRef.path}");
      }

      await requestRef.update({
        'rating': _pendingRating,
        'review': review,
      });

      // 2. Add to Shop's 'ratings' collection
      if (req.shopId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('shop_users')
            .doc(req.shopId)
            .collection('ratings')
            .doc(req.id)
            .set({
          'rating': _pendingRating,
          'review': review,
          'ratedAt': FieldValue.serverTimestamp(),
          'requestId': req.id,
          'userId': userId,
          'userName': userName,
          'userAvatar': userAvatar,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
    } catch (e) {
      debugPrint('Rating error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shop_users')
            .doc(widget.request.shopId)
            .collection('requests')
            .doc(widget.request.id)
            .snapshots(),
        builder: (context, snapshot) {
          ServiceRequestModel currentRequest = widget.request;
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.exists) {
            currentRequest = ServiceRequestModel.fromFirestore(snapshot.data!);
          }
          return _buildBody(context, currentRequest);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ServiceRequestModel req) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: req.images.isNotEmpty
                ? PageView.builder(
                    itemCount: req.images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => FullScreenImageViewer.open(context, req.images, index: index),
                        child: CachedNetworkImage(
                          imageUrl: req.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 50, color: Colors.grey)),
                        ),
                      );
                    },
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No images provided',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Device Name & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.deviceType,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.storefront_outlined, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                req.shopName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (req.modelNumber.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Model No: ${req.modelNumber}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: req.status),
                  ],
                ),
                const SizedBox(height: 16),

                // Info Pills Row
                Row(
                  children: [
                    _ActionPill(
                      label: 'Phone',
                      onTap: () => _launchPhone(req.phone),
                      isButton: true,
                    ),
                    const SizedBox(width: 8),
                    // Priority Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        'Priority: ${req.priority}',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '₹ ${req.amount}',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Builder(
                  builder: (context) {
                    bool showForwardTracking = false;
                    bool showReverseTracking = false;

                    if (req.borzoTrackingUrl != null && req.borzoTrackingUrl!.isNotEmpty) {
                      final bStatus = req.borzoStatus?.toLowerCase() ?? '';
                      final requestStatus = req.status.toLowerCase();
                      
                      if (bStatus != 'finished' && bStatus != 'delivered' && requestStatus != 'delivered' && requestStatus != 'completed') {
                        showForwardTracking = true;
                      }
                    }

                    if (req.status == 'payment_done' && req.reverseBorzoTrackingUrl != null && req.reverseBorzoTrackingUrl!.isNotEmpty) {
                      final rbStatus = req.reverseBorzoStatus?.toLowerCase() ?? '';
                      if (rbStatus != 'completed' && rbStatus != 'delivered' && rbStatus != 'finished') {
                        showReverseTracking = true;
                      }
                      showForwardTracking = false; 
                    }

                    final rbStatCheck = req.reverseBorzoStatus?.toLowerCase() ?? '';
                    if ((rbStatCheck == 'completed' || rbStatCheck == 'delivered' || rbStatCheck == 'finished') && req.status != 'delivered') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        FirebaseFirestore.instance
                            .collection('shop_users')
                            .doc(req.shopId)
                            .collection('requests')
                            .doc(req.id)
                            .update({'status': 'delivered'});
                      });
                    }

                    if (!showForwardTracking && !showReverseTracking) return const SizedBox.shrink();

                    final bool isReverse = showReverseTracking;
                    final String trackingUrl = isReverse ? req.reverseBorzoTrackingUrl! : req.borzoTrackingUrl!;
                    final String dStatus = isReverse ? (req.reverseBorzoStatus ?? 'Unknown') : (req.borzoStatus ?? 'Unknown');
                    final String dOrderId = isReverse ? (req.reverseBorzoOrderId ?? '') : (req.borzoOrderId?.toString() ?? '');
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isReverse ? Colors.teal.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isReverse ? Colors.teal.shade200 : Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_shipping, color: isReverse ? Colors.teal.shade700 : Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isReverse ? 'Return Delivery via Borzo (from ${req.shopName})' : 'Delivery via Borzo',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isReverse ? Colors.teal.shade700 : Colors.blue),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Status: ${dStatus.replaceAll('_', ' ').toUpperCase()}', 
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (dOrderId.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Order ID: #$dOrderId',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isReverse ? Colors.teal.shade700 : Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.my_location),
                                label: Text(isReverse ? 'Track Return Delivery' : 'Track Courier', style: const TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  final uri = Uri.parse(trackingUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),


                // Problem & Description
                Text(
                  req.problem.isNotEmpty ? req.problem : 'Problem Details',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    req.description.isNotEmpty
                        ? req.description
                        : 'No additional details provided',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Home-visit info card — shown only for heavy appliances (Fridge, AC, Washer, TV)
                if (req.isHeavyAppliance == true &&
                    req.status == 'in_progress') ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.home_repair_service_outlined,
                                  color: Colors.indigo.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Home Visit Service',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (req.visitScheduledAt != null) ...[
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 15, color: Colors.indigo.shade400),
                                const SizedBox(width: 6),
                                Text(
                                  'Visit scheduled for:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.indigo.shade400),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d MMM yyyy  •  h:mm a')
                                  .format(req.visitScheduledAt!),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The technician from ${req.shopName} will be at your location at the scheduled time.',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ] else ...[
                            Text(
                              'Awaiting your visit confirmation. Please go to your Requests tab to schedule a visit time.',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.indigo.shade700),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                // Technician Report
                if (req.serviceDetails != null) ...[
                  const Text(
                    'Technician Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildTechnicianReport(req),
                  const SizedBox(height: 24),
                ],

                // Customer Details
                const Text(
                  'Your Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _CustomerInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: req.phone,
                ),
                _CustomerInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: req.pickupAddress,
                ),
                _CustomerInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Created At',
                  value: req.createdAt != null
                      ? DateFormat('yyyy-MM-dd HH:mm:ss').format(req.createdAt!)
                      : 'N/A',
                ),

                // Rating Section
                _buildRatingSection(context, req),

                const SizedBox(height: 24),

                // Raise a Complaint
                _buildComplaintButton(context, req),

                const SizedBox(height: 24),
                
                // Download Invoice Button
                if (req.serviceDetails != null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => PdfInvoiceService.generateAndShowInvoice(req),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Download Invoice (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2F74F9),
                        side: const BorderSide(color: Color(0xFF2F74F9), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),
                  ),

                const SizedBox(height: 80), // Bottom padding for FAB/Button
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianReport(ServiceRequestModel req) {
    final details = req.serviceDetails!;
    final num discount = req.discountAmount ?? 0;
    final num totalWithDelivery = details.totalCost + (double.tryParse(req.borzoDeliveryCost ?? '0') ?? 0);
    final num finalTotal = totalWithDelivery - discount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportItem(
            icon: Icons.build_outlined,
            label: 'Work Done',
            value: details.description,
          ),
          const SizedBox(height: 12),
          _ReportItem(
            icon: Icons.settings_input_component_outlined,
            label: 'Parts Replaced',
            value: details.partsReplaced,
          ),
          
          if (details.photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Service Photos',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: details.photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => FullScreenImageViewer.open(context, details.photos, index: index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: details.photos[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 16),
          Divider(color: Colors.blue.shade200),
          const SizedBox(height: 8),
          _CostRow(label: 'Labor Cost:', value: '₹${details.laborCost}'),
          _CostRow(label: 'Parts Cost:', value: '₹${details.partsCost}'),
          if ((double.tryParse(req.borzoDeliveryCost ?? '0') ?? 0) > 0)
            _CostRow(label: 'Courier Delivery:', value: '₹${req.borzoDeliveryCost}'),
          
          if (discount > 0)
            _CostRow(
              label: 'Discount (${req.appliedCoupon}):', 
              value: '- ₹$discount',
              valueColor: Colors.green.shade700,
            ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Cost:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '₹${finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2F74F9),
                ),
              ),
            ],
          ),

          if (req.status == 'payment_required' && (req.discountAmount == null || req.discountAmount == 0)) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponCtrl,
                    decoration: InputDecoration(
                      hintText: 'Coupon Code',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isApplyingCoupon ? null : () => _applyCoupon(req),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isApplyingCoupon 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Apply'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                RichText(
                    text: TextSpan(children: [
                  const TextSpan(
                      text: 'Warranty: ',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                  const TextSpan(text: ' '),
                  TextSpan(
                      text: details.warranty,
                      style: const TextStyle(color: Colors.green)),
                ]))
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, List<String> images, int initialIndex) {
    FullScreenImageViewer.open(context, images, index: initialIndex);
  }

  Widget _buildRatingSection(BuildContext context, ServiceRequestModel req) {
    if (_hideRating) return const SizedBox.shrink();

    bool isCompleted = req.status.toLowerCase() == 'delivered' ||
        req.status.toLowerCase() == 'completed';

    if (!isCompleted) return const SizedBox.shrink();

    // If already rated, show Modern Thank You card
    if (req.rating != null && req.rating! > 0) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary2.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  size: 40, color: AppColors.primary2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thank You!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your feedback helps us improve.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < req.rating!
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.primary2,
                  size: 28,
                );
              }),
            ),
            if (req.review != null && req.review!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"${req.review}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Modern Interactive Rating Section
    // Orange actions, Blue accent background
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Rate Your Experience',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How was the service provided?',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Clean Modern Stars
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final isSelected = index < _pendingRating;
                return GestureDetector(
                  onTap: () => setState(() => _pendingRating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedScale(
                      scale: isSelected ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isSelected
                            ? AppColors.primary2
                            : AppColors.primary2.withOpacity(0.4),
                        size: 36,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          // Modern Input
          TextField(
            controller: _reviewCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Share your feedback (Optional)',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: AppColors.primary.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _hideRating = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Don\'t Rate',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_pendingRating > 0 && !_isSubmitting)
                      ? () => _submitRating(req)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary2,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primary2.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text(
                          'Submit Review',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintButton(BuildContext context, ServiceRequestModel req) {
    // Only show if strictly delivered
    final s = req.status.toLowerCase();
    final isCompleted = s == 'delivered';

    if (!isCompleted) return const SizedBox.shrink();

    // Serialize the request as a plain Map so RaiseComplaintScreen can use it
    // as a preSelectedRequest (skipping step 1).
    final reqMap = <String, dynamic>{
      'id': req.id,
      'shopId': req.shopId,
      'shopName': req.shopName,
      'deviceType': req.deviceType,
      'brand': req.brand,
      'createdAt':
          req.createdAt != null ? Timestamp.fromDate(req.createdAt!) : null,
    };

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RaiseComplaintScreen(preSelectedRequest: reqMap),
          ),
        ),
        icon: const Icon(
          Icons.report_problem_outlined,
          size: 20,
          color: AppColors.error,
        ),
        label: const Text(
          'Raise a Complaint',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: AppColors.error.withOpacity(0.04),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.chipPendingBg; // Default
    Color text = AppColors.chipPending;

    switch (status) {
      case 'in_progress':
      case 'in_service':
      case 'In Progress':
        bg = AppColors.chipInProgressBg;
        text = AppColors.chipInProgress;
        break;
      case 'waiting_for_confirmation':
      case 'Pending':
        bg = AppColors.chipPendingBg;
        text = AppColors.chipPending;
        break;
      case 'payment_done':
      case 'Paid':
        bg = AppColors.chipPaidBg;
        text = AppColors.chipPaid;
        break;
      case 'payment_required':
      case 'Payment':
        bg = AppColors.chipPaymentBg;
        text = AppColors.chipPayment;
        break;
      case 'declined':
      case 'Declined':
        bg = AppColors.chipDeclinedBg;
        text = AppColors.chipDeclined;
        break;
    }

    String display = status.replaceAll('_', ' ').toUpperCase();
    if (status == 'payment_done') display = 'COMPLETED';
    if (status == 'in_service') display = 'IN PROGRESS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isButton;

  const _ActionPill(
      {super.key,
      required this.label,
      required this.onTap,
      this.isButton = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReportItem(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '-',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CostRow({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                color: valueColor ?? Colors.black,
              )),
        ],
      ),
    );
  }
}

class _CustomerInfoRow extends StatelessWidget {
  final IconData icon;

  final String label;
  final String value;

  const _CustomerInfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
