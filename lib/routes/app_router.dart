import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../authentication/login.dart' as auth_login;
import '../authentication/signup.dart' as auth_signup;

import '../views/service_update_screen.dart';
import '../views/chat_list_screen.dart';
import '../views/chat_detail_screen.dart';
import '../views/profile_screen.dart';
import '../views/warranty_screen.dart';
import '../views/warranty_history_screen.dart';
import '../views/warranty_detail_screen.dart';
import '../views/notifications_screen.dart';
import '../views/nearby_shop_screen.dart';
import '../views/shop_details_screen.dart';
import '../views/search_screen.dart';
import '../views/product_details_screen.dart';
import '../views/request_service_screen.dart';
import '../views/edit_profile_screen.dart';
import '../views/home_screen.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const auth_login.LoginScreen(),
        );
      case AppRoutes.signup:
        return MaterialPageRoute(
          builder: (_) => const auth_signup.SignupScreen(),
        );
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case AppRoutes.orders:
        return MaterialPageRoute(builder: (_) => ServiceUpdateScreen());
      case AppRoutes.requests:
        return MaterialPageRoute(builder: (_) => ServiceUpdateScreen());
      case AppRoutes.chat:
        return MaterialPageRoute(builder: (_) => const ChatListScreen());
      case AppRoutes.chatDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(args: args ?? const {}),
        );
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case AppRoutes.warranty:
        return MaterialPageRoute(builder: (_) => const WarrantyScreen());
      case AppRoutes.warrantyHistory:
        return MaterialPageRoute(builder: (_) => const WarrantyHistoryScreen());
      case AppRoutes.warrantyDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => WarrantyDetailScreen(data: args ?? const {}),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => NotificationsScreen());
      case AppRoutes.nearbyShops:
        return MaterialPageRoute(builder: (_) => NearbyShopsScreen());
      case AppRoutes.shopDetails:
        final args = settings.arguments;
        return MaterialPageRoute(builder: (_) => ShopDetailsScreen(args: args));
      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case AppRoutes.productDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(data: args ?? const {}),
        );
      case AppRoutes.requestService:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RequestServiceScreen(data: args ?? const {}),
        );
      case AppRoutes.editProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EditProfileScreen(data: args ?? const {}),
        );
      default:
        return MaterialPageRoute(builder: (_) => HomeScreen());
    }
  }
}
