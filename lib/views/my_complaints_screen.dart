import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../data/models/complaint_model.dart';
import '../data/repositories/complaint_repository.dart';
import 'raise_complaint_screen.dart';

class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'My Complaints',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RaiseComplaintScreen(),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'New',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
      body: uid.isEmpty
          ? const Center(child: Text('Please log in to view complaints.'))
          : StreamBuilder<List<ComplaintModel>>(
              stream: ComplaintRepository().getComplaints(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error loading complaints.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                final complaints = snap.data ?? [];
                if (complaints.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: complaints.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _ComplaintCard(complaint: complaints[i]),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Complaints Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t raised any complaints. If you face an issue with a completed service request, tap below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RaiseComplaintScreen(),
                  ),
                ),
                icon: const Icon(Icons.report_problem_outlined, size: 18),
                label: const Text(
                  'Raise a Complaint',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Complaint card
// ─────────────────────────────────────────────────────────────────────────────

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintCard({required this.complaint});

  static const Map<String, Color> _statusColors = {
    'open': Color(0xFFFFB500),
    'in_review': AppColors.primary,
    'resolved': AppColors.success,
  };

  static const Map<String, Color> _statusBgColors = {
    'open': Color(0xFFFFF4D6),
    'in_review': Color(0xFFE0EDFF),
    'resolved': Color(0xFFCFF6DF),
  };

  static const Map<String, String> _statusLabels = {
    'open': 'Open',
    'in_review': 'In Review',
    'resolved': 'Resolved',
  };

  static const Map<String, Color> _categoryColors = {
    'Service Quality': Color(0xFF4285F4),
    'Overcharging': Color(0xFFEB5685),
    'Delay': Color(0xFFFFB500),
    'Rude Behavior': Color(0xFFEF4444),
    'Damaged Device': Color(0xFF8B5CF6),
    'Other': Color(0xFF6B6E75),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[complaint.status] ?? AppColors.textSecondary;
    final statusBg = _statusBgColors[complaint.status] ?? AppColors.divider;
    final statusLabel = _statusLabels[complaint.status] ?? complaint.status;
    final catColor = _categoryColors[complaint.category] ?? AppColors.textSecondary;
    final dateStr = complaint.createdAt != null
        ? DateFormat('dd MMM yyyy').format(complaint.createdAt!)
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: category chip + status chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  complaint.category,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: catColor,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            complaint.title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // Description (clamped)
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Footer: device + date
          Row(
            children: [
              const Icon(
                Icons.build_circle_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  complaint.deviceType.isNotEmpty
                      ? complaint.deviceType
                      : complaint.shopName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
