import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedGroup; // 'Computer Peripherals' | 'Household Electronics'
  String? _selectedSubcat;

  final List<String> _peripherals = const [
    'Laptop',
    'MotherBoard',
    'Keyboard',
    'Mouse',
    'Printer',
    'Monitor',
  ];
  final List<String> _household = const [
    'Fridge',
    'Washing Machine',
    'AC',
    'TV',
    'Microwave',
  ];

  final List<String> _filterDistances = ['500m', '1km', '3km', '5km'];
  String _selectedDistance = '5km'; // Default
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPosition = pos;
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  double _getFilterRadiusInKm() {
    switch (_selectedDistance) {
      case '500m': return 0.5;
      case '1km': return 1.0;
      case '3km': return 3.0;
      case '5km': return 5.0;
      default: return 5.0;
    }
  }


  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
             
                  const Text(
                    'Search',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _openFilter,
                      ),
                     
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search shops...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? const Icon(Icons.mic_none)
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        ),
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
            const SizedBox(height: 8),
            // Filter Chips Row
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
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
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: (_selectedSubcat == null)
                      ? FirebaseFirestore.instance
                            .collection('shop_users')
                            .snapshots()
                      : FirebaseFirestore.instance
                            .collection('shop_users')
                            .where(
                              'subcategories',
                              arrayContains: _selectedSubcat,
                            )
                            .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var docs = snapshot.data?.docs ?? [];
                    final q = _searchCtrl.text.trim().toLowerCase();
                    if (q.isNotEmpty) {
                      docs = docs.where((d) {
                        final name =
                            ((d.data()['companyLegalName'] ??
                                        d.data()['companyLegalname'] ??
                                        d.data()['companylegalName'] ??
                                        'Shop')
                                    as String)
                                .toLowerCase();
                        return name.contains(q);
                      }).toList();
                    }

                    // Distance Filtering Logic
                    if (_userPosition != null) {
                      final radiusKm = _getFilterRadiusInKm();
                      docs = docs.where((doc) {
                        final data = doc.data();
                        
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
                    }

                    if (docs.isEmpty) {
                      return const Center(child: Text('No shops found'));
                    }
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .8,
                          ),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data();
                        final id = docs[i].id;
                        final title =
                            (data['companyLegalName'] ??
                                    data['companyLegalname'] ??
                                    data['companylegalName'] ??
                                    'Shop')
                                .toString();
                        final image = data['imageUrl'] as String?;
                        return _SearchResultCard(
                          shopId: id,
                          title: title,
                          image: image,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final selectedColor = AppColors.primary.withOpacity(.12);
            final selectedText = AppColors.primary;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Computer Peripherals'),
                        selected: _selectedGroup == 'Computer Peripherals',
                        selectedColor: selectedColor,
                        labelStyle: TextStyle(
                          color: _selectedGroup == 'Computer Peripherals'
                              ? selectedText
                              : Colors.black87,
                        ),
                        onSelected: (s) {
                          setModalState(() {
                            _selectedGroup = s ? 'Computer Peripherals' : null;
                            _selectedSubcat = null;
                          });
                          setState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Household Electronics'),
                        selected: _selectedGroup == 'Household Electronics',
                        selectedColor: selectedColor,
                        labelStyle: TextStyle(
                          color: _selectedGroup == 'Household Electronics'
                              ? selectedText
                              : Colors.black87,
                        ),
                        onSelected: (s) {
                          setModalState(() {
                            _selectedGroup = s ? 'Household Electronics' : null;
                            _selectedSubcat = null;
                          });
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedGroup != null) ...[
                    const Text(
                      'Subcategory',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          (_selectedGroup == 'Computer Peripherals'
                                  ? _peripherals
                                  : _household)
                              .map(
                                (s) => ChoiceChip(
                                  label: Text(s),
                                  selected: _selectedSubcat == s,
                                  selectedColor: selectedColor,
                                  avatar: _selectedSubcat == s
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.orange,
                                          size: 18,
                                        )
                                      : null,
                                  labelStyle: TextStyle(
                                    color: _selectedSubcat == s
                                        ? selectedText
                                        : Colors.black87,
                                  ),
                                  onSelected: (_) {
                                    setModalState(() {
                                      _selectedSubcat = _selectedSubcat == s
                                          ? null
                                          : s;
                                    });
                                    setState(() {});
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedGroup = null;
                              _selectedSubcat = null;
                            });
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final String shopId;
  final String title;
  final String? image;
  const _SearchResultCard({
    required this.shopId,
    required this.title,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetails,
        arguments: {'shopId': shopId, 'title': title, 'image': image},
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: (image != null && image!.isNotEmpty)
                  ? Image.network(
                      image!,
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
                  Row(
                    children: const [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('4.4  •  12,534', style: TextStyle(fontSize: 12)),
                    ],
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
