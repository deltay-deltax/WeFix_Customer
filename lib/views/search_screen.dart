import 'dart:async';

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/utils/shop_image_helper.dart';
import '../widgets/shop_async_image.dart';
import '../widgets/shop_rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

// ─── Full subcategory lists (must match Firestore exactly) ────────────────────
const List<String> _kHouseholdSubs = [
  'Refrigerator (Fridge)',
  'Washing Machine',
  'Microwave Oven',
  'Air Conditioner (AC)',
  'Water Purifier / RO System',
  'Geyser / Water Heater',
  'Mixer / Grinder',
  'Induction Cooktop',
  'Electric Kettle',
  'Vacuum Cleaner',
  'Electric Iron',
  'Air Cooler',
  'Inverter / UPS',
  'Smart TV / LED TV',
  'Home Theatre System',
  'Room Heater',
  'Chimney / Exhaust Fan',
  'Dishwasher',
];

const List<String> _kComputerSubs = [
  'Laptop',
  'Desktop CPU',
  'Monitor',
  'Printer',
  'Scanner',
  'Keyboard',
  'Mouse',
  'External Hard Disk / SSD / HDD',
  'RAM',
  'Graphic Card (GPU)',
  'Motherboard',
  'SMPS / Power Supply',
  'Router / Modem',
  'Webcam',
  'Headphones / Headset',
  'Microphone',
  'UPS (for PC)',
  'Pen Drive (logical repair / recovery)',
];
// ─────────────────────────────────────────────────────────────────────────────

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  // Filter state
  String? _selectedGroup;   // 'Household Electronics' | 'Computer & Peripherals'
  String? _selectedSubcat;  // exact Firestore subcategory value

  final List<String> _filterDistances = ['1km', '3km', '5km', '7km'];
  String _selectedDistance = '7km';

  Position? _userPosition;
  bool _isLoadingLocation = true;

  // Shops matched via service-name search (shop_users subcollection)
  Set<String> _serviceMatchedShopIds = {};
  bool _isSearchingServices = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────────────────────
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    if (mounted) setState(() { _userPosition = pos; _isLoadingLocation = false; });
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
      case '1km':  return 1.0;
      case '3km':  return 3.0;
      case '5km':  return 5.0;
      case '7km':  return 7.0;
      default:     return 7.0;
    }
  }

  // ── Service-name search (debounced) ─────────────────────────────────────────
  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      if (mounted) setState(() { _serviceMatchedShopIds = {}; _isSearchingServices = false; });
      return;
    }
    setState(() => _isSearchingServices = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _searchServices(q));
  }

  /// Queries shop_users/{shopId}/services where name starts with [q].
  /// Firestore doesn't support LIKE, so we use the standard prefix-range trick.
  Future<void> _searchServices(String q) async {
    final raw = q.trim();
    if (raw.isEmpty) {
      if (mounted) setState(() { _serviceMatchedShopIds = {}; _isSearchingServices = false; });
      return;
    }

    // Try two prefix variants:
    //   1. Exactly as-typed  (e.g. "bat")
    //   2. First letter capitalised (e.g. "Bat") — matches "Battery Replacement"
    final variants = <String>{
      raw,
      raw[0].toUpperCase() + (raw.length > 1 ? raw.substring(1) : ''),
    };

    final ids = <String>{};

    for (final v in variants) {
      try {
        final snap = await FirebaseFirestore.instance
            .collectionGroup('services')
            .where('name', isGreaterThanOrEqualTo: v)
            .where('name', isLessThanOrEqualTo: '$v\uf8ff')
            .get();

        // Service path: shop_users/{shopId}/services/{serviceId}
        // parent       = CollectionReference  (services)
        // parent.parent = DocumentReference    (shop doc)
        for (final d in snap.docs) {
          final shopId = d.reference.parent.parent?.id;
          if (shopId != null) ids.add(shopId);
        }
      } catch (_) {
        // ignore individual variant failures
      }
    }

    if (mounted) setState(() { _serviceMatchedShopIds = ids; _isSearchingServices = false; });
  }

  // ── Filter helpers ──────────────────────────────────────────────────────────

  /// Whether a shop doc passes the current text search.
  /// Matches: shop name OR subcategories array OR service-name lookup.
  bool _matchesSearch(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    final data = doc.data();

    // 1. Shop name
    final name = ((data['companyLegalName'] ??
            data['companyLegalname'] ??
            data['companylegalName'] ??
            '') as String)
        .toLowerCase();
    if (name.contains(q)) return true;

    // 2. Subcategories array (partial match)
    final subs = (data['subcategories'] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase());
    if (subs.any((s) => s.contains(q))) return true;

    // 3. Service-name match (from async query above)
    if (_serviceMatchedShopIds.contains(doc.id)) return true;

    return false;
  }

  /// Whether a shop doc is within the selected distance radius.
  bool _withinRadius(Map<String, dynamic> data) {
    if (_userPosition == null) return true; // no location, show all
    try {
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return false;
      final lat = double.parse(address['lat'] as String);
      final lng = double.parse(address['lng'] as String);
      final dist = _calculateDistance(
          _userPosition!.latitude, _userPosition!.longitude, lat, lng);
      return dist <= _getFilterRadiusInKm();
    } catch (_) {
      return false;
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Search',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.filter_list),
                        if (_selectedSubcat != null)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: _openFilter,
                  ),
                ],
              ),
            ),

            // ── Search bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search shop, service, or device…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearchingServices
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : _searchCtrl.text.isEmpty
                          ? null
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

            // ── Active filter chips ───────────────────────────────────────────
            if (_selectedSubcat != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
                child: Wrap(
                  spacing: 6,
                  children: [
                    Chip(
                      label: Text(_selectedSubcat!,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.primary)),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() {
                        _selectedSubcat = null;
                        _selectedGroup = null;
                      }),
                    ),
                  ],
                ),
              ),

            // ── Distance chips ────────────────────────────────────────────────
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
                        onSelected: (_) => setState(() => _selectedDistance = dist),
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Results ────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _buildStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        _isLoadingLocation) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = snapshot.data?.docs ?? [];

                    // Apply text + service search
                    docs = docs.where(_matchesSearch).toList();

                    // Apply distance filter
                    if (_userPosition != null) {
                      docs = docs.where((d) => _withinRadius(d.data())).toList();
                    }

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No shops found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
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
                        final title = (data['companyLegalName'] ??
                                data['companyLegalname'] ??
                                data['companylegalName'] ??
                                'Shop')
                            .toString();
                        return _SearchResultCard(
                          shopId: id,
                          title: title,
                          image: ShopImageHelper.getImage(data),
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

  /// Firestore stream: if a subcategory filter is active, restrict to that.
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('registered_shop_users');

    if (_selectedSubcat != null) {
      q = q.where('subcategories', arrayContains: _selectedSubcat);
    }

    return q.snapshots();
  }

  // ── Filter bottom sheet ─────────────────────────────────────────────────────
  void _openFilter() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final sel = AppColors.primary.withOpacity(.12);
            final selText = AppColors.primary;

            final subcats = _selectedGroup == 'Household Electronics'
                ? _kHouseholdSubs
                : _selectedGroup == 'Computer & Peripherals'
                    ? _kComputerSubs
                    : <String>[];

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.92,
              builder: (_, scrollCtrl) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    const Text('Filters',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 12),
                    const Text('Category',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _groupChip('Household Electronics', setModalState, sel, selText),
                        _groupChip('Computer & Peripherals', setModalState, sel, selText),
                      ],
                    ),
                    if (_selectedGroup != null) ...[
                      const SizedBox(height: 12),
                      const Text('Subcategory',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: subcats
                            .map((s) => ChoiceChip(
                                  label: Text(s),
                                  selected: _selectedSubcat == s,
                                  selectedColor: sel,
                                  avatar: _selectedSubcat == s
                                      ? Icon(Icons.check_circle,
                                          color: selText, size: 18)
                                      : null,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: _selectedSubcat == s
                                        ? selText
                                        : Colors.black87,
                                  ),
                                  onSelected: (_) {
                                    setModalState(() {
                                      _selectedSubcat =
                                          _selectedSubcat == s ? null : s;
                                    });
                                    setState(() {});
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _groupChip(String label, StateSetter setModalState,
      Color sel, Color selText) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedGroup == label,
      selectedColor: sel,
      labelStyle: TextStyle(
        color: _selectedGroup == label ? selText : Colors.black87,
      ),
      onSelected: (s) {
        setModalState(() {
          _selectedGroup = s ? label : null;
          _selectedSubcat = null;
        });
        setState(() {});
      },
    );
  }
}

// ─── Search result card ───────────────────────────────────────────────────────
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
              child: ShopAsyncImage(
                shopId: shopId,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.storefront)),
                ),
              ),
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
                  ShopRating(shopId: shopId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
