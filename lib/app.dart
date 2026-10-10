import 'package:flutter/material.dart';

import 'config/api_configuration.dart';
import 'repositories/http_resource_repository.dart';
import 'repositories/resource_repository.dart';
import 'screens/home_screen.dart';

class BridgePdxApp extends StatefulWidget {
  const BridgePdxApp({this.repository, super.key});

  final ResourceRepository? repository;

  @override
  State<BridgePdxApp> createState() => _BridgePdxAppState();
}

class _BridgePdxAppState extends State<BridgePdxApp> {
  late final ResourceRepository _repository;
  late final bool _ownsRepository;

  @override
  void initState() {
    super.initState();
    _ownsRepository = widget.repository == null;
    _repository =
        widget.repository ??
        HttpResourceRepository(baseUri: ApiConfiguration().baseUri);
  }

  @override
  void dispose() {
    if (_ownsRepository) _repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BridgePDX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B)),
        useMaterial3: true,
      ),
      home: HomeScreen(repository: _repository),
    );
  }
}
