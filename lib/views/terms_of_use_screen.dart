import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Terms of Use',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Last updated
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Last updated: February 23, 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _Intro(),
          const SizedBox(height: 8),
          _Section(
            number: '1',
            title: 'Acceptance of Terms',
            body:
                'By downloading, installing, or using the WeFix application ("App"), you agree to be bound by these Terms of Use ("Terms"). If you do not agree to these Terms, please do not use the App. These Terms constitute a legally binding agreement between you and WeFix Technologies Pvt. Ltd.',
          ),
          _Section(
            number: '2',
            title: 'Description of Services',
            body:
                'WeFix provides a platform connecting users with certified repair technicians for consumer electronics and home appliances. Our services include:\n\n• Repair booking and tracking\n• Warranty recording and reminders\n• Technician matching and scheduling\n• Payment processing for completed services\n\nWeFix acts as an intermediary platform and does not directly employ technicians. All repair services are performed by independent service professionals.',
          ),
          _Section(
            number: '3',
            title: 'User Accounts',
            body:
                'You must create an account to access most features of the App. You are responsible for:\n\n• Providing accurate and complete registration information\n• Maintaining the confidentiality of your account credentials\n• All activities that occur under your account\n• Notifying us immediately of any unauthorized use\n\nWeFix reserves the right to suspend or terminate accounts that violate these Terms.',
          ),
          _Section(
            number: '4',
            title: 'Payments & Refunds',
            body:
                'All payments are processed through secure third-party payment gateways. By making a payment, you agree that:\n\n• Service charges are non-refundable once a repair has commenced\n• Diagnostic fees are non-refundable\n• Refunds for cancelled bookings (before service commencement) will be processed within 5–7 business days\n• WeFix is not liable for payment failures caused by your bank or payment provider\n\nAll prices are inclusive of applicable taxes unless otherwise stated.',
          ),
          _Section(
            number: '5',
            title: 'Warranty & Repairs',
            body:
                'WeFix provides a limited repair warranty on replaced parts for 30 days from the date of service. This warranty:\n\n• Covers only the specific parts that were replaced\n• Does not cover physical damage caused after the repair\n• Does not cover software issues unrelated to the repair\n• Is void if the device is serviced by a third party after our repair\n\nThe product manufacturer\'s warranty is a separate agreement and is not managed by WeFix.',
          ),
          _Section(
            number: '6',
            title: 'Privacy & Data',
            body:
                'Your privacy is important to us. We collect and use your data in accordance with our Privacy Policy. By using the App, you consent to:\n\n• Collection of device information and usage data\n• Storage of warranty and repair records\n• Receipt of service notifications and reminders\n• Use of location data for technician matching\n\nWe do not sell your personal data to third parties.',
          ),
          _Section(
            number: '7',
            title: 'Limitation of Liability',
            body:
                'To the maximum extent permitted by applicable law, WeFix shall not be liable for:\n\n• Indirect, incidental, or consequential damages\n• Loss of data or damage to your device during service\n• Actions or omissions of independent technicians\n• Interruption or unavailability of the App\n\nOur total liability to you shall not exceed the amount paid for the specific service in dispute.',
          ),
          _Section(
            number: '8',
            title: 'Governing Law',
            body:
                'These Terms are governed by the laws of India. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts of Bengaluru, Karnataka, India. You agree to submit to the personal jurisdiction of such courts.',
          ),
          _Section(
            number: '9',
            title: 'Changes to Terms',
            body:
                'WeFix reserves the right to modify these Terms at any time. We will provide notice of significant changes through the App or via email. Continued use of the App after changes constitutes acceptance of the revised Terms.',
          ),
          _Section(
            number: '10',
            title: 'Contact',
            body:
                'If you have questions about these Terms, please contact us:\n\nEmail: support@wekeep.com\nPhone: +91 98767 87653\nAddress: CMR Institute of Technology, Bengaluru, India',
            isLast: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to WeFix',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please read these Terms of Use carefully before using our services. These terms govern your use of the WeFix platform and all related services.',
          style: TextStyle(
            fontSize: 14.5,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final bool isLast;

  const _Section({
    required this.number,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.iconGrey,
          children: [
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.65,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
