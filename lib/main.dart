import 'package:alto/routes/app_routes.dart';
import 'package:alto/screens/Home/HomeScreen.dart';
import 'package:alto/screens/Home/InitPairingScreen.dart';
import 'package:alto/screens/Home/ScanPairingScreen.dart';
import 'package:alto/screens/theme/theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alto',
      theme: MaterialTheme(MaterialTheme.lightScheme()).light(),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.initPairing: (_) => const InitPairingScreen(),
        AppRoutes.scanPairing: (_) => const ScanPairingScreen(),
      },
    );
  }
}
