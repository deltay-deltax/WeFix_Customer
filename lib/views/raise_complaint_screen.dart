import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../data/models/complaint_model.dart';
import '../data/repositories/complaint_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point.
// Pass [preSelectedRequest] when launching from ServiceRequestDetailScreen.
// ─────────────────────────────────────────────────────────────────────────────
class RaiseComplaintScreen extends StatefulWidget {
  /// When non-null the picker step is skipped and this request is pre-selected.
  final Map<String, dynamic>? preSelectedRequest;

  const RaiseComplaintScreen({super.key, this.preSelectedRequest});

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  // Step tracking
  static const int _stepPick = 0;
  static const int _stepForm = 1;
  int _currentStep = _stepPick;

  // Selected request
  Map<String, dynamic>? _selectedRequest;

  // Form state
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = '';
  bool _isSubmitting = false;

  // Completed requests loading
  final _repo = ComplaintRepository();
  List<Map<String, dynamic>> _completedRequests = [];
  bool _isLoadingRequests = true;
  String? _loadError;

  static const List<String> _categories = [
    'Service Quality',
    'Overcharging',
    'Delay',
    'Rude Behavior',
    'Damaged Device',
    'Other',
  ];

  static const Map<String, Color> _categoryColors = {
    'Service Quality': Color(0xFF4285F4),
    'Overcharging': Color(0xFFEB5685),
    'Delay': Color(0xFFFFB500),
    'Rude Behavior': Color(0xFFEF4444),
    'Damaged Device': Color(0xFF8B5CF6),
    'Other': Color(0xFF6B6E75),
  };

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedRequest != null) {
      _selectedRequest = widget.preSelectedRequest;
      _currentStep = _stepForm;
    }
    _loadCompletedRequests();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCompletedRequests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _isLoadingRequests = false;
        _loadError = 'Please log in to raise a complaint.';
      });
      return;
    }
    try {
      final requests = await _repo.getCompletedRequests(uid);
      setState(() {
        _completedRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRequests = false;
        _loadError = 'Could not load requests. Please try again.';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a complaint category.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';
      final userName = user?.displayName ?? 'Anonymous';
      final req = _selectedRequest!;

      final complaint = ComplaintModel(
        userId: uid,
        userName: userName,
        requestId: req['id'] ?? '',
        shopId: req['shopId'] ?? '',
        shopName: req['shopName'] ?? '',
        deviceType: req['deviceType'] ?? '',
        category: _selectedCategory,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );

      await _repo.submitComplaint(complaint);

      if (!mounted) return;
      _showSuccessSheet();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit complaint: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _SuccessSheet(
            onDone: () {
              Navigator.of(context).pop(); // sheet
              Navigator.of(context).pop(); // screen
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          _currentStep == _stepPick ? 'Select Request' : 'Raise a Complaint',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == _stepForm && widget.preSelectedRequest == null) {
              setState(() => _currentStep = _stepPick);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body:
          _currentStep == _stepPick
              ? _buildRequestPicker()
              : _buildComplaintForm(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — Request Picker
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRequestPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF3B5FDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Which service request?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Select the completed job you want to complain about.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildRequestList()),
      ],
    );
  }

  Widget _buildRequestList() {
    if (_isLoadingRequests) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoadingRequests = true;
                    _loadError = null;
                  });
                  _loadCompletedRequests();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_completedRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 18),
              Text(
                'No completed requests',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can only raise a complaint against a completed service request.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _completedRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final req = _completedRequests[i];
        return _RequestPickerCard(
          request: req,
          onTap: () {
            setState(() {
              _selectedRequest = req;
              _currentStep = _stepForm;
            });
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — Complaint Form
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildComplaintForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Selected request summary card
          _SelectedRequestCard(request: _selectedRequest!),
          const SizedBox(height: 20),

          // Category section
          _FormLabel(label: 'Complaint Category'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final color =
                      _categoryColors[cat] ?? AppColors.textSecondary;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? color : AppColors.divider,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                : [],
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),

          // Title
          _FormLabel(label: 'Complaint Title'),
          const SizedBox(height: 8),
          _AppTextField(
            controller: _titleCtrl,
            hint: 'e.g. Device returned with scratches',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter a title.';
              if (v.trim().length < 5) return 'Title must be at least 5 characters.';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Description
          _FormLabel(label: 'Describe Your Issue'),
          const SizedBox(height: 8),
          _AppTextField(
            controller: _descCtrl,
            hint: 'Provide as much detail as possible so we can resolve your issue quickly...',
            maxLines: 5,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please describe the issue.';
              }
              if (v.trim().length < 20) {
                return 'Please provide at least 20 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                      : const Text(
                        'Submit Complaint',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RequestPickerCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;

  const _RequestPickerCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final deviceType = request['deviceType'] as String? ?? 'Device';
    final shopName = request['shopName'] as String? ?? 'Shop';
    final brand = request['brand'] as String? ?? '';
    final date = (request['createdAt'] as Timestamp?)?.toDate();
    final dateStr =
        date != null ? DateFormat('dd MMM yyyy').format(date) : 'N/A';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.isNotEmpty ? '$brand $deviceType' : deviceType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.chipPaidBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.chipPaid,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _SelectedRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final deviceType = request['deviceType'] as String? ?? 'Device';
    final brand = request['brand'] as String? ?? '';
    final shopName = request['shopName'] as String? ?? 'Shop';
    final date = (request['createdAt'] as Timestamp?)?.toDate();
    final dateStr =
        date != null ? DateFormat('dd MMM yyyy').format(date) : 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.isNotEmpty ? '$brand $deviceType' : deviceType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$shopName · $dateStr',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.chipPaidBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Completed',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.chipPaid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessSheet({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Complaint Submitted!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We\'ve received your complaint and will review it within 2–3 business days. You can track its status in "My Complaints".',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
