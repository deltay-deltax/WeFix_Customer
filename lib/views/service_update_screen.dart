import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_routes.dart';
import '../data/models/service_model.dart';
import 'service_request_detail_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ServiceUpdateScreen extends StatefulWidget {
  @override
  State<ServiceUpdateScreen> createState() => _ServiceUpdateScreenState();
}

class _ServiceUpdateScreenState extends State<ServiceUpdateScreen> {
  final _searchCtrl = TextEditingController();
  String _status = 'All Status';
  late Razorpay _razorpay;
  ServiceRequestModel? _currentPayingRequest; // Track which request is being paid for

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
    double? amount = double.tryParse(req.amount.replaceAll(RegExp(r'[^0-9.]'), ''));
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
        'email': 'user@example.com' // You might want to get actual email if available
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
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
                  _filterChip('New', 'waiting_for_confirmation'),
                  const SizedBox(width: 8),
                  _filterChip('In Progress', 'in_progress'),
                  const SizedBox(width: 8),
                  _filterChip('All', 'All Status'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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
                    requests = requests
                        .where((req) => req.status == _status)
                        .toList();
                  }

                  if (requests.isEmpty) {
                    return const Center(child: Text('No requests found'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final req = requests[i];
                      return _buildRequestCard(req);
                    },
                  );
                },
              ),
            ),
          ],
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
                          req.yourName.isEmpty ? 'Unknown User' : req.yourName, // Or Brand/Model if preferred
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
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
                     errorBuilder: (_,__,___) => const SizedBox.shrink(),
                   ),
                 ),
               ],


              const SizedBox(height: 12),
              
              Row(
                children: [
                  _labelPill(req.priority, Colors.orange.shade100, Colors.orange.shade900),
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
                        builder: (_) => ServiceRequestDetailScreen(request: req),
                      ),
                    );
                  },
                  child: const Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        onPressed: () => _updateStatus(req, 'in_progress'),
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
                    label: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(text: label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
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
        child: Column( // Use Column to take width
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
      case 'waiting_for_confirmation': return Colors.blue.shade100;
      case 'in_progress': return Colors.indigo.shade100;
      case 'declined': return Colors.red.shade100;
      case 'payment_required': return Colors.orange.shade100;
      case 'payment_done': return Colors.teal.shade100;
      case 'payment_on_delivery': return Colors.purple.shade100;
      
      case 'Pending': return Colors.orange.shade100;
      case 'Accepted': return Colors.green.shade100;
      case 'In Progress': return Colors.indigo.shade100; // Legacy support
      case 'Completed': return Colors.green.shade100;
      default: return Colors.grey.shade200;
    }
  }

  Color _fg() {
    switch (status) {
      case 'waiting_for_confirmation': return Colors.blue.shade800;
      case 'in_progress': return Colors.indigo.shade800;
      case 'declined': return Colors.red.shade800;
      case 'payment_required': return Colors.deepOrange.shade800;
      case 'payment_done': return Colors.teal.shade800;
      case 'payment_on_delivery': return Colors.purple.shade800;

      case 'Pending': return Colors.orange.shade800;
      case 'Accepted': return Colors.green.shade800;
      case 'In Progress': return Colors.indigo.shade800; // Legacy support
      case 'Completed': return Colors.green.shade800;
      default: return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    String display = status == 'payment_done' 
        ? 'COMPLETED' 
        : status.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        display,
        style: TextStyle(color: _fg(), fontWeight: FontWeight.bold, fontSize: 10),
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
