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
    // Validate amount
    double? amount =
        double.tryParse(req.amount.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount for payment')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('Pay Online'),
                subtitle: const Text('Razorpay, Cards, Netbanking'),
                onTap: () {
                  Navigator.pop(context);
                  _startRazorpay(req, amount);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.money, color: Colors.green),
                title: const Text('Pay on Delivery'),
                subtitle: const Text('Cash / UPI upon service completion'),
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(req, 'payment_on_delivery');
                },
              ),
            ],
          ),
        );
      },
    );
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                     
                      ],
                    ),
                  ),
                  _StatusPill(status: req.status),
                ],
              ),

              // Image Section if exists
              if (req.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    req.images.first,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],

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
              _infoText('Amount: ', '₹${req.amount}'),

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

              if (req.status == 'in_progress') ...[
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
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.location_on,
                                  color: Colors.red, size: 28),
                              onPressed: () async {
                                final uri = Uri.parse(gmapUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                            );
                          } else {
                            // Render a disabled icon so the user knows there is no location provided
                            return const Icon(Icons.location_off, color: Colors.grey, size: 24);
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
      if (shopDoc.exists && shopDoc.data() != null) {
        final data = shopDoc.data() as Map<String, dynamic>;
        shopAddress = data['address'] ?? data['addressLocality'] ?? widget.req.shopName;
        shopPhone = data['phone'] ?? data['phoneNumber'] ?? '';
      }

      final res = await BorzoService().calculateOrder(
        userAddress: widget.req.pickupAddress,
        userName: widget.req.yourName,
        userPhone: widget.req.phone,
        shopAddress: shopAddress,
        shopName: widget.req.shopName,
        shopPhone: shopPhone,
      );
      if (mounted) {
        setState(() {
          _deliveryCost = res['payment_amount']?.toString() ?? 'N/A';
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
        if (shopDoc.exists && shopDoc.data() != null) {
          final data = shopDoc.data() as Map<String, dynamic>;
          shopAddress = data['address'] ?? data['addressLocality'] ?? widget.req.shopName;
          shopPhone = data['phone'] ?? data['phoneNumber'] ?? '';
        }

        await BorzoService().createOrder(
          userAddress: widget.req.pickupAddress,
          userName: widget.req.yourName,
          userPhone: widget.req.phone,
          shopAddress: shopAddress,
          shopName: widget.req.shopName,
          shopPhone: shopPhone,
          requestId: widget.req.id,
          shopId: widget.req.shopId,
          requiredStartDatetime: _selectedDate!.toIso8601String(),
        );
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
          _isLoadingCost
              ? const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
              : _errorMessage != null
                  ? Text('Could not load delivery options: $_errorMessage', style: const TextStyle(color: Colors.red))
                  : Column(
                      children: [
                        RadioListTile<int>(
                          value: 0,
                          groupValue: _selectedOption,
                          onChanged: (v) => setState(() => _selectedOption = v!),
                          title: const Text('Drop Self'),
                          subtitle: const Text('I will drop the device myself'),
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.blue.shade600,
                        ),
                        RadioListTile<int>(
                          value: 1,
                          groupValue: _selectedOption,
                          onChanged: (v) => setState(() => _selectedOption = v!),
                          title: Text('Drop by Courier (₹$_deliveryCost)'),
                          subtitle: const Text('A Borzo courier will pick it up'),
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.blue.shade600,
                        ),
                      ],
                    ),
          if (_selectedOption == 1) ...[
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              onPressed: _isSubmitting || _isLoadingCost ? null : _confirm,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm & Accept',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

