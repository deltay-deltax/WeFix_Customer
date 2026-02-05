import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'core/constants/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WeFixApp());
}

// Backward compatibility for tests or code referencing MyApp
class MyApp extends WeFixApp {
  const MyApp({super.key});
}

class WeFixApp extends StatelessWidget {
  const WeFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WeFix',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4285F4)),
          useMaterial3: true,
        ),
        initialRoute: FirebaseAuth.instance.currentUser == null
            ? AppRoutes.login
            : AppRoutes.home,
        onGenerateRoute: AppRouter.generate,
      ),
    );
  }
}
