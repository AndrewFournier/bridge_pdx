import 'package:flutter/material.dart';

import 'config/api_configuration.dart';
import 'repositories/http_resource_repository.dart';
import 'repositories/http_report_repository.dart';
import 'repositories/report_repository.dart';
import 'repositories/resource_repository.dart';
import 'screens/home_screen.dart';

class BridgePdxApp extends StatefulWidget {
  const BridgePdxApp({this.repository, this.reportRepository, super.key});

  final ResourceRepository? repository;
  final ReportRepository? reportRepository;

  @override
  State<BridgePdxApp> createState() => _BridgePdxAppState();
}

class _BridgePdxAppState extends State<BridgePdxApp> {
  late final ResourceRepository _repository;
  late final bool _ownsRepository;
  late final ReportRepository _reportRepository;
  late final bool _ownsReportRepository;

  @override
  void initState() {
    super.initState();
    _ownsRepository = widget.repository == null;
    _repository =
        widget.repository ??
        HttpResourceRepository(baseUri: ApiConfiguration().baseUri);
    _ownsReportRepository = widget.reportRepository == null;
    _reportRepository =
        widget.reportRepository ??
        HttpReportRepository(baseUri: ApiConfiguration().baseUri);
  }

  @override
  void dispose() {
    if (_ownsRepository) _repository.close();
    if (_ownsReportRepository) _reportRepository.close();
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
      home: HomeScreen(
        repository: _repository,
        reportRepository: _reportRepository,
      ),
    );
  }
}
