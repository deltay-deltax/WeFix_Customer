// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class BootScreen extends StatefulWidget {
//   const BootScreen({super.key});

//   @override
//   State<BootScreen> createState() => _BootScreenState();
// }

// class _BootScreenState extends State<BootScreen>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//   late final Animation<double> _fade;
//   bool _navigated = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     );
//     _fade = Tween<double>(
//       begin: 0.35,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//     _controller.repeat(reverse: true);

//     // Kick off simple boot routing after a short delay
//     scheduleMicrotask(_routeNext);
//   }

//   Future<void> _routeNext() async {
//     if (_navigated || !mounted) return;
//     await Future<void>.delayed(const Duration(milliseconds: 900));
//     if (!mounted) return;
//     _navigated = true;
//     final user = FirebaseAuth.instance.currentUser;
//     final next = (user == null) ? Routes.login : Routes.userHome;
//     // ignore: use_build_context_synchronously
//     Navigator.of(context).pushReplacementNamed(next);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: FadeTransition(
//           opacity: _fade,
//           child: Image.asset(
//             'assets/images/logo1.png',
//             width: 180,
//             height: 180,
//             fit: BoxFit.contain,
//           ),
//         ),
//       ),
//     );
//   }
// }
