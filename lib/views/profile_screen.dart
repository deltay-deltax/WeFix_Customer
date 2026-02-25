import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_colors.dart';
import '../viewModels/profile_viewmodel.dart';
import '../core/services/auth_service.dart';
import 'terms_of_use_screen.dart';
import 'contact_us_screen.dart';
import 'extend_warranty_screen.dart';
import 'raise_complaint_screen.dart';
import 'my_complaints_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, child) => Scaffold(
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(0),
              children: [
                // Header row
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 26, 0, 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Profile",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      Row(
                        children: [
                          // Removed Notification and More icons
                        ],
                      ),
                    ],
                  ),
                ),
                // Profile section (hardcoded image for now)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: vm.changeAvatar,
                        child: CircleAvatar(
                          radius: 37,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              (vm.photoUrl != null && vm.photoUrl!.isNotEmpty)
                              ? NetworkImage(vm.photoUrl!)
                              : null,
                          child: (vm.photoUrl == null || vm.photoUrl!.isEmpty)
                              ? Icon(
                                  Icons.local_shipping,
                                  size: 45,
                                  color: Colors.grey[700],
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vm.name.isEmpty ? 'User' : vm.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 23,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              vm.email.isEmpty ? ' ' : vm.email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            if (vm.currentLocation != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.grey[700],
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      vm.currentLocation!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (vm.fullAddress != null) ...[
                              SizedBox(height: 8),
                              _AddressDetails(map: vm.fullAddress!),
                            ],
                            SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.editProfile,
                                  arguments: {
                                    'name': vm.name,
                                    'phone': vm.phone,
                                  },
                                );
                                // Refresh profile data on return
                                vm.initUser(); // Need to make _initUser public or accessible
                              },
                              child: Text(
                                "Edit Profile",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                // Actions card (hardcoded)
                SizedBox(height: 15),
                // Actions card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 18),
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                ProfileActionTile(
                        icon: Icons.engineering,
                        label: "Book a Technician",
                        onTap: () => _showComingSoon(context),
                      ),
                      ProfileActionTile(
                        icon: Icons.verified_user,
                        label: "Record Warranty",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.warranty);
                        },
                      ),
                      ProfileActionTile(
                        icon: Icons.security_update_good,
                        label: "Extend Warranty",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExtendWarrantyScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileActionTile(
                        icon: Icons.description_outlined,
                        label: "Terms of Use",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermsOfUseScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileActionTile(
                        icon: Icons.contact_support_outlined,
                        label: "Contact Us",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactUsScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileActionTile(
                        icon: Icons.report_problem_outlined,
                        label: "Raise a Complaint",
                        iconColor: Colors.redAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RaiseComplaintScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileActionTile(
                        icon: Icons.assignment_late_outlined,
                        label: "My Complaints",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyComplaintsScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 28,
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 17,
                          color: Colors.red.shade300,
                        ),
                        onTap: () async {
                          await AuthService().signOut();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                // Removed 'Track Your Orders' card
                SizedBox(height: 25),
                // Favorite Shops header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Favorite Shops",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _FavoriteShopsGrid(),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Requests',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: 3,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, AppRoutes.requests);
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, AppRoutes.chat);
                  break;
                case 3:
                  // already here
                  break;
              }
            },
          ),
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Coming Soon! 🚀',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Booking a technician directly through the app is coming very soon. Stay tuned for updates!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.55,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Hardcoded as a builder method for readability, but you can extract if needed.
Widget ProfileActionTile({
  required IconData icon,
  required String label,
  bool last = false,
  VoidCallback? onTap,
  Color? iconColor,
}) {
  return Column(
    children: [
      ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blue, size: 28),
        title: Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 17,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
      if (!last) Divider(height: 0, thickness: 1, indent: 15, endIndent: 15),
    ],
  );
}

class _FavoriteShopsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Login to see your favorite shops'),
      );
    }
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc.snapshots(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final favIds =
            (userSnap.data?.data()?['favoriteShops'] as List?)
                ?.cast<String>() ??
            const [];
        if (favIds.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No favorite shops yet'),
          );
        }
        final ids = favIds.length > 10 ? favIds.sublist(0, 10) : favIds;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('shop_users')
              .where(FieldPath.documentId, whereIn: ids)
              .snapshots(),
          builder: (context, shopSnap) {
            if (shopSnap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = shopSnap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No favorite shops found'),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .8,
              ),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data();
                final name =
                    (d['companyLegalName'] ??
                            d['companyLegalname'] ??
                            d['companylegalName'] ??
                            'Shop')
                        .toString();
                final image = d['imageUrl'] as String?;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      d['shopId'] = docs[i].id; // Ensure shopId is present for ProductDetailsScreen
                      Navigator.pushNamed(
                        context, 
                        AppRoutes.productDetails,  // Ensure consistent route name
                        arguments: d 
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: image != null && image.isNotEmpty
                              ? Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _ph(),
                                )
                              : _ph(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _ph() => Container(
    color: Colors.grey[300],
    child: const Center(child: Icon(Icons.image_not_supported)),
  );
}

class _AddressDetails extends StatelessWidget {
  final Map<String, dynamic> map;
  const _AddressDetails({required this.map});
  @override
  Widget build(BuildContext context) {
    TextStyle k = TextStyle(fontSize: 13, color: Colors.grey[700]);
    TextStyle v = const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    String _val(String key) => (map[key] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Address 1: ', style: k),
            Flexible(child: Text(_val('addressLine1'), style: v)),
          ],
        ),
        Row(
          children: [
            Text('Address 2: ', style: k),
            Flexible(child: Text(_val('addressLine2'), style: v)),
          ],
        ),
        Row(
          children: [
            Text('City: ', style: k),
            Text(_val('city'), style: v),
          ],
        ),
        Row(
          children: [
            Text('Locality: ', style: k),
            Text(_val('locality'), style: v),
          ],
        ),
        Row(
          children: [
            Text('State: ', style: k),
            Text(_val('state'), style: v),
          ],
        ),
        Row(
          children: [
            Text('Country: ', style: k),
            Text(_val('country'), style: v),
          ],
        ),
        Row(
          children: [
            Text('Pincode: ', style: k),
            Text(_val('pincode'), style: v),
          ],
        ),
        Row(
          children: [
            Text('Lat: ', style: k),
            Text(_val('latitude'), style: v),
            const SizedBox(width: 8),
            Text('Lng: ', style: k),
            Text(_val('longitude'), style: v),
          ],
        ),
      ],
    );
  }
}
