import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';
import 'administrator_dashboard_screen.dart';
import 'administrator_login_screen.dart';

class AdminSessionScreen extends StatefulWidget {
  const AdminSessionScreen({required this.repository, super.key});
  final AdminRepository repository;

  @override
  State<AdminSessionScreen> createState() => _AdminSessionScreenState();
}

class _AdminSessionScreenState extends State<AdminSessionScreen> {
  AdministratorProfile? _profile;
  bool _loading = true;
  bool _signedOut = false;
  bool _connectionError = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _loading = true;
      _connectionError = false;
    });
    try {
      if (!await widget.repository.hasValidSession()) {
        if (mounted) setState(() => _signedOut = true);
        return;
      }
      final profile = await widget.repository.getMe();
      if (mounted) {
        setState(() {
          _profile = profile;
          _signedOut = false;
        });
      }
    } on AdminRepositoryException catch (error) {
      if (!mounted) return;
      if (error.type == AdminRepositoryErrorType.unauthorized) {
        await widget.repository.logout();
        setState(() => _signedOut = true);
      } else {
        setState(() => _connectionError = true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSignedOut() {
    setState(() {
      _profile = null;
      _signedOut = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(key: Key('admin-session-loading')),
        ),
      );
    }
    if (_connectionError) {
      return Scaffold(
        appBar: AppBar(title: const Text('BridgePDX Administration')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 56),
                const SizedBox(height: 12),
                const Text('Unable to verify the administrator session.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('admin-session-retry'),
                  onPressed: _restoreSession,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_signedOut || _profile == null) {
      return AdministratorLoginScreen(
        repository: widget.repository,
        onAuthenticated: _restoreSession,
      );
    }
    return AdministratorDashboardScreen(
      repository: widget.repository,
      profile: _profile!,
      onSignedOut: _showSignedOut,
    );
  }
}
