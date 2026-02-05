import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'dart:math' show cos, sqrt, asin;
import '../core/constants/app_routes.dart';
import '../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> _categories = const [
    {'name': 'Laptop', 'asset': 'assets/icon/laptop.png'},
    {'name': 'Phone', 'asset': 'assets/icon/icons8-mobile-phone-50.png'},
    {'name': 'Fridge', 'asset': 'assets/icon/icons8-fridge-48.png'},
    {'name': 'TV', 'asset': 'assets/icon/icons8-tv-48.png'},
    {'name': 'Washer', 'asset': 'assets/icon/icons8-washing-machine-48.png'},
    {'name': 'Board', 'asset': 'assets/icon/icons8-motherboard-40.png'},
    {'name': 'AC', 'asset': 'assets/icon/icons8-ac-94.png'},
  ];

  final List<String> _filterDistances = ['500m', '1km', '3km', '5km'];
  String _selectedDistance = '5km'; // Default
  Position? _userPosition;

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _userPosition = pos;
    });
  }

  // Haversine Formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  double _getFilterRadiusInKm() {
    switch (_selectedDistance) {
      case '500m':
        return 0.5;
      case '1km':
        return 1.0;
      case '3km':
        return 3.0;
      case '5km':
        return 5.0;
      default:
        return 5.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
          currentIndex: 0,
          selectedItemColor: AppColors.navSelected,
          unselectedItemColor: AppColors.navUnselected,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.pushReplacementNamed(context, AppRoutes.requests);
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
        body: SafeArea(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Removed Gear Icon (Menu) as requested
                    const SizedBox(
                        width: 24), // Placeholder for alignment or remove
                    const Text(
                      'WeFix',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    CircleAvatar(
                      child: IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.notifications,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                  child: IgnorePointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search any Product..',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: const Icon(Icons.mic_none),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
              // Filter Chips Row
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterDistances.map((dist) {
                      final isSelected = _selectedDistance == dist;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(dist),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedDistance = dist;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary2.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary2
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary2
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = _selectedCategory == cat['name'];
                    return InkWell(
                      onTap: () => setState(() {
                        _selectedCategory =
                            selected ? null : (cat['name'] as String);
                      }),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56, // Circle size relevant to screenshot
                            height: 56,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? Colors.orange.withOpacity(
                                      0.2) // Light orange bg when selected
                                  : Colors.blue
                                      .withOpacity(0.1), // Or grey/blue tint
                              // Screenshot shows a light background for icons
                            ),
                            child:
                                Image.asset(cat['asset']!, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.orange // Orange text when selected
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 24), // Wider spacing
                  itemCount: _categories.length,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 200, // Increased height to prevent overflow
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Right Icon (Background decoration)
                      Positioned(
                        right: 10,
                        bottom: 30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.storefront_outlined,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "Electronics Hub" Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ELECTRONICS HUB',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Grand Opening\nSale Live!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.deepOrange,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Visit Shop',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Shops Near You ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View all'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _selectedCategory == null
                      ? FirebaseFirestore.instance
                          .collection('shop_users')
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('registered_shop_users')
                          .where(
                            'subcategories',
                            arrayContains: _selectedCategory,
                          )
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];

                    // Filter by distance if User Position is available
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>
                        filteredDocs = docs;
                    /* // UNCOMMENT FOR PRODUCTION: Distance Filtering Logic
                    if (_userPosition != null) {
                      final radiusKm = _getFilterRadiusInKm();
                      filteredDocs = docs.where((doc) {
                        final data = doc.data();
                        
                        // Parse Lat/Lng from address map
                        // Structure: address: { lat: "...", lng: "..." }
                        try {
                          final address = data['address'] as Map<String, dynamic>?;
                          if (address == null) return false;
                          
                          final latStr = address['lat'] as String?;
                          final lngStr = address['lng'] as String?;
                          
                          if (latStr == null || lngStr == null) return false;
                          
                          final double lat = double.parse(latStr);
                          final double lng = double.parse(lngStr);
                          
                          final double distance = _calculateDistance(
                            _userPosition!.latitude, 
                            _userPosition!.longitude, 
                            lat, 
                            lng
                          );
                          
                          return distance <= radiusKm;
                        } catch (e) {
                          return false; // Error parsing or finding location
                        }
                      }).toList();
                    } */

                    if (filteredDocs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No shops found near you')),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .8,
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (_, i) {
                        final data = filteredDocs[i].data();
                        final id = filteredDocs[i].id;
                        final name = (data['companyLegalName'] ??
                                data['companyLegalname'] ??
                                data['companylegalName'] ??
                                'Shop')
                            .toString();
                        final imageUrl = data['imageUrl'] as String?;
                        return _ShopProductCard(
                          shopId: id,
                          title: name,
                          imageUrl: imageUrl,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed unused _SortFilterRow

class _ShopProductCard extends StatelessWidget {
  final String shopId;
  final String title;
  final String? imageUrl;
  const _ShopProductCard({
    required this.shopId,
    required this.title,
    required this.imageUrl,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetails,
        arguments: {'shopId': shopId, 'title': title, 'image': imageUrl},
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  
                  // Real Ratings Stream
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('shop_users')
                        .doc(shopId)
                        .collection('ratings')
                        .snapshots(),
                    builder: (context, snapshot) {
                       double avg = 0.0;
                       int count = 0;
                       
                       if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                         final docs = snapshot.data!.docs;
                         count = docs.length;
                         final total = docs.fold<double>(0, (sum, doc) {
                           final data = doc.data() as Map<String, dynamic>;
                           return sum + (data['rating'] is int ? (data['rating'] as int).toDouble() : (data['rating'] as double? ?? 0.0));
                         });
                         avg = total / count;
                       }

                       return Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            count == 0 ? 'New' : '${avg.toStringAsFixed(1)}  •  $count',
                            style: const TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w500,
                              color: Colors.black87
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
}
