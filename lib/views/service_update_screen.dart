import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_routes.dart';
import '../data/models/service_model.dart';
import 'service_request_detail_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/borzo_service.dart';

class ServiceUpdateScreen extends StatefulWidget {
  @override
  State<ServiceUpdateScreen> createState() => _ServiceUpdateScreenState();
}

class _ServiceUpdateScreenState extends State<ServiceUpdateScreen> {
  final _searchCtrl = TextEditingController();
  String _status = 'All Status';
  late Razorpay _razorpay;
  ServiceRequestModel?
      _currentPayingRequest; // Track which request is being paid for

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _updateStatus(ServiceRequestModel req, String newStatus) async {
    try {
      if (req.reference != null) {
        await req.reference!.update({'status': newStatus});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Document Reference missing')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_currentPayingRequest != null) {
      _updateStatus(_currentPayingRequest!, 'payment_done');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Successful: ${response.paymentId}')),
      );
    }
    _currentPayingRequest = null;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
    _currentPayingRequest = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  void _showPaymentDialog(ServiceRequestModel req) {
    double baseAmount = (req.serviceDetails?.totalCost ??
            double.tryParse(req.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0)
        .toDouble();
    double deliveryCost = double.tryParse(req.borzoDeliveryCost ?? '0') ?? 0;
    double amount = baseAmount + deliveryCost;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount for payment')),
      );
      return;
    }

    _startRazorpay(req, amount);
  }

  void _startRazorpay(ServiceRequestModel req, double amount) {
    _currentPayingRequest = req;
    var options = {
      'key': 'rzp_test_RVRJZ0MVFBEcOX',
      'amount': (amount * 100).toInt(), // in paise
      'name': 'WeFix Service',
      'description': 'Payment for ${req.deviceType} Service',
      'prefill': {
        'contact': req.phone,
        'email':
            'user@example.com' // You might want to get actual email if available
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _showAcceptBottomSheet(ServiceRequestModel req) {
    // Heavy appliances (Fridge, AC, Washer, TV) go through home-visit flow:
    // the customer schedules a visit rather than dropping the device off.
    if (req.isHeavyAppliance == true) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _HeavyApplianceScheduleSheet(
            req: req,
            onStatusUpdate: (status) => _updateStatus(req, status),
          ),
        ),
      );
      return;
    }

    // Portable devices (Laptop, Mobile, etc.) — existing self-drop / courier sheet.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _AcceptRequestBottomSheet(
            req: req,
            onStatusUpdate: (status) => _updateStatus(req, status),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Service Requests',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _openFilter,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6, bottom: 20),
                child: Text(
                  'Manage and process all service requests',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by customer, status...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Filter Pills Row (Mockup style)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip('All', 'All Status'),
                    const SizedBox(width: 8),
                    _filterChip('New', 'waiting_for_confirmation'),
                    const SizedBox(width: 8),
                    _filterChip('In Progress', 'in_progress'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('requests')
                    .where('userId', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data?.docs ?? [];
                  List<ServiceRequestModel> requests = docs
                      .map((d) => ServiceRequestModel.fromFirestore(d))
                      .toList();

                  final q = _searchCtrl.text.trim().toLowerCase();
                  if (q.isNotEmpty) {
                    requests = requests.where((req) {
                      return req.deviceType.toLowerCase().contains(q) ||
                          req.problem.toLowerCase().contains(q) ||
                          req.yourName.toLowerCase().contains(q);
                    }).toList();
                  }

                  if (_status != 'All Status') {
                    requests =
                        requests.where((req) => req.status == _status).toList();
                  }

                  if (requests.isEmpty) {
                    return const Center(child: Text('No requests found'));
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final req = requests[i];
                      return _buildRequestCard(req);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.chat);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }

  Widget _buildRequestCard(ServiceRequestModel req) {
    final bool isWaiting = req.status == 'waiting_for_confirmation';
    final bool isPaymentRequired = req.status == 'payment_required';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceRequestDetailScreen(request: req),
          ),
        );
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.shopName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: req.status),
                ],
              ),

              // Image Section if exists (removed as per request)

              const SizedBox(height: 12),

              Row(
                children: [
                  _labelPill(req.priority, Colors.orange.shade100,
                      Colors.orange.shade900),
                  if (isWaiting) ...[
                    // Already shown in status, but maybe we want extra flair?
                    // User prompt: 'Waiting for Confirmation'
                  ]
                ],
              ),

              const SizedBox(height: 12),
              _infoText('Problem: ', req.problem),
              _infoText('Phone: ', req.phone),
              _infoText('Address: ', req.pickupAddress),
              Builder(
                builder: (context) {
                  double baseAmnt = (req.serviceDetails?.totalCost ??
                          double.tryParse(
                              req.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                          0)
                      .toDouble();
                  double deliveryAmnt =
                      double.tryParse(req.borzoDeliveryCost ?? '0') ?? 0;
                  double totalAmnt = baseAmnt + deliveryAmnt;
                  return _infoText(
                      'Amount: ', '₹${totalAmnt.toStringAsFixed(0)}');
                },
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceRequestDetailScreen(request: req),
                      ),
                    );
                  },
                  child: const Text('View Details',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              if (isWaiting) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                        onPressed: () => _showAcceptBottomSheet(req),
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () => _updateStatus(req, 'declined'),
                        child: const Text('Deny'),
                      ),
                    ),
                  ],
                ),
              ],

              if (isPaymentRequired) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showPaymentDialog(req),
                    icon: const Icon(Icons.payment),
                    label: const Text('Pay Now',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],

              // In-progress banner — only shown for PORTABLE devices (no Borzo order yet).
              // Heavy appliances (home-visit flow) skip this entirely.
              if (req.status == 'in_progress' &&
                  (req.isHeavyAppliance != true) &&
                  (req.borzoOrderId == null || req.borzoOrderId!.isEmpty)) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Please drop/courier your product to the service provider",
                          style: TextStyle(
                            color: Color(0xFF2F74F9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('registered_shop_users')
                            .doc(req.shopId)
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const SizedBox.shrink();
                          }
                          final shopData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final gmapUrl = shopData['gmapUrl'] as String?;

                          if (gmapUrl != null && gmapUrl.isNotEmpty) {
                            return ElevatedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(gmapUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.map_rounded, size: 16),
                              label: const Text('Shop Location', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue.shade700,
                                elevation: 0,
                                side: BorderSide(color: Colors.blue.shade200),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          } else {
                            // Render a disabled icon so the user knows there is no location provided
                            return const Icon(Icons.location_off,
                                color: Colors.grey, size: 24);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating(ServiceRequestModel req, int rating) async {
    try {
      if (req.shopId.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      // 1. Add to shop ratings
      final ratingRef = FirebaseFirestore.instance
          .collection('shop_users')
          .doc(req.shopId)
          .collection('ratings')
          .doc(req.id);

      batch.set(ratingRef, {
        'rating': rating,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'requestId': req.id,
        'createdAt': FieldValue.serverTimestamp(),
        'userName': req.yourName, // Captured at rating time
      });

      // 2. Mark request as rated
      if (req.reference != null) {
        batch.update(req.reference!, {
          'rating': rating,
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You rated this service $rating stars!')),
      );
    } catch (e) {
      debugPrint('Error placing rating: $e');
    }
  }

  Widget _labelPill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
                text: label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[700])),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String statusKey) {
    bool isSelected = _status == statusKey;
    // Special case for 'All'
    if (label == 'All' && _status == 'All Status') isSelected = true;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'All') {
            _status = 'All Status';
          } else {
            _status = statusKey;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade900 : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _openFilter() {
    const statuses = [
      'All Status',
      'waiting_for_confirmation',
      'Pending',
      'Accepted',
      'In Progress',
      'Completed',
    ];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true, // Allows full height/custom constraints better
      builder: (_) => Container(
        width: double.infinity, // Force full width
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          // Use Column to take width
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by status',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (final s in statuses)
                  ChoiceChip(
                    label: Text(s.replaceAll('_', ' ')),
                    selected: _status == s,
                    onSelected: (_) {
                      setState(() => _status = s);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heavy-appliance schedule sheet
// Shown when customer taps Accept on a waiting_for_confirmation heavy-appliance
// request.  No courier involved — the customer just picks a visit date+time.
// ─────────────────────────────────────────────────────────────────────────────
class _HeavyApplianceScheduleSheet extends StatefulWidget {
  final ServiceRequestModel req;
  final Function(String) onStatusUpdate;

  const _HeavyApplianceScheduleSheet(
      {Key? key, required this.req, required this.onStatusUpdate})
      : super(key: key);

  @override
  State<_HeavyApplianceScheduleSheet> createState() =>
      _HeavyApplianceScheduleSheetState();
}

class _HeavyApplianceScheduleSheetState
    extends State<_HeavyApplianceScheduleSheet> {
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (t == null) return;
    setState(() {
      _selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _confirm() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a visit date & time')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('shop_users')
          .doc(widget.req.shopId)
          .collection('requests')
          .doc(widget.req.id)
          .update({
        'visitScheduledAt': Timestamp.fromDate(_selectedDate!),
        'visitConfirmedByUser': true,
      });
      widget.onStatusUpdate('in_progress');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.req.amount.isEmpty ? '—' : '₹${widget.req.amount}';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Schedule a Home Visit',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'The service provider will come to your location to inspect and fix your ${widget.req.deviceType}.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
          ),
          const SizedBox(height: 20),

          // Quoted amount
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.currency_rupee, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quoted Service Amount',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date + time picker
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Tap to choose visit date & time'
                          : DateFormat('EEE, d MMM yyyy  •  h:mm a')
                              .format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 14.5,
                        color: _selectedDate == null
                            ? Colors.grey
                            : Colors.black87,
                        fontWeight: _selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSubmitting ? null : _confirm,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Confirm Visit & Accept Amount',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({super.key, required this.status});

  Color _bg() {
    switch (status) {
      case 'waiting_for_confirmation':
        return Colors.blue.shade100;
      case 'in_progress':
      case 'in_service':
        return Colors.indigo.shade100;
      case 'declined':
        return Colors.red.shade100;
      case 'payment_required':
        return Colors.orange.shade100;
      case 'payment_done':
        return Colors.teal.shade100;
      case 'payment_on_delivery':
        return Colors.purple.shade100;

      case 'Pending':
        return Colors.orange.shade100;
      case 'Accepted':
        return Colors.green.shade100;
      case 'In Progress':
        return Colors.indigo.shade100; // Legacy support
      case 'Completed':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _fg() {
    switch (status) {
      case 'waiting_for_confirmation':
        return Colors.blue.shade800;
      case 'in_progress':
      case 'in_service':
        return Colors.indigo.shade800;
      case 'declined':
        return Colors.red.shade800;
      case 'payment_required':
        return Colors.deepOrange.shade800;
      case 'payment_done':
        return Colors.teal.shade800;
      case 'payment_on_delivery':
        return Colors.purple.shade800;

      case 'Pending':
        return Colors.orange.shade800;
      case 'Accepted':
        return Colors.green.shade800;
      case 'In Progress':
        return Colors.indigo.shade800; // Legacy support
      case 'Completed':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    String display = status.replaceAll('_', ' ').toUpperCase();
    if (status == 'payment_done') display = 'COMPLETED';
    if (status == 'in_service') display = 'IN PROGRESS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        display,
        style:
            TextStyle(color: _fg(), fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}

String _mon(int m) => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][m - 1];

class _AcceptRequestBottomSheet extends StatefulWidget {
  final ServiceRequestModel req;
  final Function(String) onStatusUpdate;

  const _AcceptRequestBottomSheet(
      {Key? key, required this.req, required this.onStatusUpdate})
      : super(key: key);

  @override
  State<_AcceptRequestBottomSheet> createState() =>
      _AcceptRequestBottomSheetState();
}

class _AcceptRequestBottomSheetState extends State<_AcceptRequestBottomSheet> {
  bool _isLoadingCost = true;
  String? _deliveryCost;
  String? _errorMessage;
  int _selectedOption = 0; // 0: Self, 1: Courier
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  String _sanitizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return "919999999999";
    if (cleaned.length == 10) return "91$cleaned";
    if (cleaned.length > 10 && cleaned.startsWith('91')) return cleaned;
    if (cleaned.length > 10) return cleaned.substring(cleaned.length - 10);
    return "919999999999";
  }

  String _formatDateWithOffset(DateTime date) {
    String iso = date.toIso8601String();
    int offsetMins = date.timeZoneOffset.inMinutes;
    if (offsetMins == 0) return "${iso}Z";
    String sign = offsetMins < 0 ? "-" : "+";
    int h = (offsetMins.abs() / 60).floor();
    int m = offsetMins.abs() % 60;
    return "$iso$sign${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _calculateCost();
  }

  Future<void> _calculateCost() async {
    try {
      final shopDoc = await FirebaseFirestore.instance
          .collection('registered_shop_users')
          .doc(widget.req.shopId)
          .get();

      String shopAddress = widget.req.shopName;
      String shopPhone = '';
      double? shopLat;
      double? shopLng;

      if (shopDoc.exists && shopDoc.data() != null) {
        final data = shopDoc.data() as Map<String, dynamic>;

        final rawAddr = data['address'] ?? data['addressLocality'];
        if (rawAddr is Map) {
          final parts = [];
          if (rawAddr['line1'] != null) parts.add(rawAddr['line1']);
          if (rawAddr['line2'] != null) parts.add(rawAddr['line2']);
          if (rawAddr['city'] != null) parts.add(rawAddr['city']);
          if (rawAddr['pincode'] != null) parts.add(rawAddr['pincode']);
          shopAddress = parts.join(', ');

          shopLat = double.tryParse(rawAddr['lat']?.toString() ?? '');
          shopLng = double.tryParse(rawAddr['lng']?.toString() ?? '');
        } else if (rawAddr is String) {
          shopAddress = rawAddr;
        } else if (rawAddr != null) {
          shopAddress = rawAddr.toString();
        }

        final rawPhone = data['phone'] ?? data['phoneNumber'];
        //... keep rest identical
        if (rawPhone is String) {
          shopPhone = rawPhone;
        } else if (rawPhone != null) {
          shopPhone = rawPhone.toString();
        }
      }

      final fwdRes = await BorzoService().calculateOrder(
        userAddress: widget.req.pickupAddress,
        userLat: widget.req.pickupLat,
        userLng: widget.req.pickupLng,
        userName: widget.req.yourName,
        userPhone: _sanitizePhone(widget.req.phone),
        shopAddress: shopAddress,
        shopLat: shopLat,
        shopLng: shopLng,
        shopName: widget.req.shopName,
        shopPhone: _sanitizePhone(shopPhone),
      );

      final revRes = await BorzoService().calculateOrder(
        userAddress: shopAddress,
        userLat: shopLat,
        userLng: shopLng,
        userName: widget.req.shopName,
        userPhone: _sanitizePhone(shopPhone),
        shopAddress: widget.req.pickupAddress,
        shopLat: widget.req.pickupLat,
        shopLng: widget.req.pickupLng,
        shopName: widget.req.yourName,
        shopPhone: _sanitizePhone(widget.req.phone),
      );

      final d1 = double.tryParse(fwdRes['order']?['payment_amount']?.toString() ?? fwdRes['payment_amount']?.toString() ?? '0') ?? 0;
      final d2 = double.tryParse(revRes['order']?['payment_amount']?.toString() ?? revRes['payment_amount']?.toString() ?? '0') ?? 0;

      if (mounted) {
        setState(() {
          _deliveryCost = (d1 + d2).toStringAsFixed(0);
          _isLoadingCost = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingCost = false;
        });
      }
    }
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (t == null) return;
    setState(() {
      _selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      _selectedTime = t;
    });
  }

  Future<void> _confirm() async {
    if (_selectedOption == 1) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a pickup Date & Time')),
        );
        return;
      }
      setState(() => _isSubmitting = true);
      try {
        final shopDoc = await FirebaseFirestore.instance
            .collection('registered_shop_users')
            .doc(widget.req.shopId)
            .get();
        String shopAddress = widget.req.shopName;
        String shopPhone = '';
        double? shopLat;
        double? shopLng;

        if (shopDoc.exists && shopDoc.data() != null) {
          final data = shopDoc.data() as Map<String, dynamic>;

          final rawAddr = data['address'] ?? data['addressLocality'];
          if (rawAddr is Map) {
            final parts = [];
            if (rawAddr['line1'] != null) parts.add(rawAddr['line1']);
            if (rawAddr['line2'] != null) parts.add(rawAddr['line2']);
            if (rawAddr['city'] != null) parts.add(rawAddr['city']);
            if (rawAddr['pincode'] != null) parts.add(rawAddr['pincode']);
            shopAddress = parts.join(', ');

            shopLat = double.tryParse(rawAddr['lat']?.toString() ?? '');
            shopLng = double.tryParse(rawAddr['lng']?.toString() ?? '');
          } else if (rawAddr is String) {
            shopAddress = rawAddr;
          } else if (rawAddr != null) {
            shopAddress = rawAddr.toString();
          }

          final rawPhone = data['phone'] ?? data['phoneNumber'];
          if (rawPhone is String) {
            shopPhone = rawPhone;
          } else if (rawPhone != null) {
            shopPhone = rawPhone.toString();
          }
        }

        await BorzoService().createOrder(
          userAddress: widget.req.pickupAddress,
          userLat: widget.req.pickupLat,
          userLng: widget.req.pickupLng,
          userName: widget.req.yourName,
          userPhone: _sanitizePhone(widget.req.phone),
          shopAddress: shopAddress,
          shopLat: shopLat,
          shopLng: shopLng,
          shopName: widget.req.shopName,
          shopPhone: _sanitizePhone(shopPhone),
          requestId: widget.req.id,
          shopId: widget.req.shopId,
          requiredStartDatetime: _formatDateWithOffset(_selectedDate!),
        );

        final doubleCost = (double.tryParse(_deliveryCost ?? '0') ?? 0);
        await FirebaseFirestore.instance
            .collection('shop_users')
            .doc(widget.req.shopId)
            .collection('requests')
            .doc(widget.req.id)
            .update({
          'borzoDeliveryCost': doubleCost.toStringAsFixed(2),
        });

        widget.onStatusUpdate('in_progress');
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book Borzo Courier: $e')),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      widget.onStatusUpdate('in_progress');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm Request',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              RadioListTile<int>(
                value: 0,
                groupValue: _selectedOption,
                onChanged: (v) => setState(() => _selectedOption = v!),
                title: const Text('Drop Self'),
                subtitle: const Text(
                    'You will have to pick it up yourself from the store when ready'),
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.blue.shade600,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Courier unavailable: $_errorMessage',
                      style: const TextStyle(color: Colors.red)),
                )
              else
                RadioListTile<int>(
                  value: 1,
                  groupValue: _selectedOption,
                  onChanged: (v) => setState(() => _selectedOption = v!),
                  title: _isLoadingCost
                      ? Row(
                          children: const [
                            Text('Drop by Courier'),
                            SizedBox(width: 8),
                            SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          ],
                        )
                      : Text(
                          'Drop by Courier (Pickup+Return: ₹$_deliveryCost)'),
                  subtitle: const Text(
                      'A Borzo courier will pick up and return the device'),
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.blue.shade600,
                ),
            ],
          ),
          if (_selectedOption == 1) ...[
            const SizedBox(height: 16),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: Icon(Icons.calendar_today, color: Colors.blue.shade600),
              title: Text(_selectedDate == null
                  ? 'Select Pickup Time'
                  : DateFormat('MMM d, yyyy - h:mm a').format(_selectedDate!)),
              onTap: _pickDateTime,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed:
                  _isSubmitting || (_isLoadingCost && _selectedOption == 1)
                      ? null
                      : _confirm,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm & Accept',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
