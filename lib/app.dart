import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class BridgePdxApp extends StatelessWidget {
  const BridgePdxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BridgePDX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
