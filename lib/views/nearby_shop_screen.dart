import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_routes.dart';
import '../viewModels/nearby_shop_viewmodel.dart';
import '../widgets/nearby_shop_card.dart';

class NearbyShopsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NearbyShopsViewModel(),
      child: Consumer<NearbyShopsViewModel>(
        builder: (context, vm, child) => Scaffold(
          body: SafeArea(
            child: vm.loading
                ? Center(child: CircularProgressIndicator())
                : vm.error != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 40),
                              SizedBox(height: 12),
                              Text(
                                'Failed to load nearby shops',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              SizedBox(height: 6),
                              Text(
                                vm.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: vm.fetch,
                                child: Text('Retry'),
                              )
                            ],
                          ),
                        ),
                      )
                    : ListView(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(23, 21, 0, 18),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, size: 28, color: Colors.black),
                      SizedBox(width: 10),
                      Text(
                        "Nearby Shops",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 27,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.search, color: Colors.grey[600]),
                      SizedBox(width: 16),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                        child: Icon(Icons.notifications_none, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 14),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 23),
                  child: TextField(
                    onChanged: vm.setQuery,
                    decoration: InputDecoration(
                      hintText: 'Search shops or locations',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Verified Shops
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 23, vertical: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Verified Shops",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 23,
                        ),
                      ),
                      Text(
                        "See All",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: vm.filteredVerified.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (context, i) => NearbyShopCard(shop: vm.filteredVerified[i]),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 23, vertical: 13),
                  child: Text(
                    "Other Nearby Shops",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: vm.filteredOthers.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (context, i) => NearbyShopCard(shop: vm.filteredOthers[i]),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
          // No bottom navigation on Nearby Shops
        ),
      ),
    );
  }
}
