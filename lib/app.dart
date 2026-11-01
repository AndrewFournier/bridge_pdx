import 'package:flutter/material.dart';

import 'config/api_configuration.dart';
import 'repositories/http_resource_repository.dart';
import 'repositories/http_report_repository.dart';
import 'repositories/http_admin_repository.dart';
import 'repositories/admin_repository.dart';
import 'repositories/report_repository.dart';
import 'repositories/resource_repository.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_session_screen.dart';
import 'storage/admin_token_store.dart';

class BridgePdxApp extends StatefulWidget {
  const BridgePdxApp({
    this.repository,
    this.reportRepository,
    this.adminRepository,
    this.initialRoute,
    super.key,
  });

  final ResourceRepository? repository;
  final ReportRepository? reportRepository;
  final AdminRepository? adminRepository;
  final String? initialRoute;

  @override
  State<BridgePdxApp> createState() => _BridgePdxAppState();
}

class _BridgePdxAppState extends State<BridgePdxApp> {
  late final ResourceRepository _repository;
  late final bool _ownsRepository;
  late final ReportRepository _reportRepository;
  late final bool _ownsReportRepository;
  late final AdminRepository _adminRepository;
  late final bool _ownsAdminRepository;

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
    _ownsAdminRepository = widget.adminRepository == null;
    _adminRepository =
        widget.adminRepository ??
        HttpAdminRepository(
          baseUri: ApiConfiguration().baseUri,
          tokenStore: SecureAdminTokenStore(),
        );
  }

  @override
  void dispose() {
    if (_ownsRepository) _repository.close();
    if (_ownsReportRepository) _reportRepository.close();
    if (_ownsAdminRepository) _adminRepository.close();
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
      initialRoute:
          widget.initialRoute ??
          const String.fromEnvironment(
            'BRIDGE_PDX_INITIAL_ROUTE',
            defaultValue: '/',
          ),
      routes: {
        '/': (_) => HomeScreen(
          repository: _repository,
          reportRepository: _reportRepository,
        ),
        '/admin': (_) => AdminSessionScreen(repository: _adminRepository),
      },
    );
  }
}
