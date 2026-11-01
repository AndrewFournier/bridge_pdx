import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

class AdministratorReportDetailScreen extends StatefulWidget {
  const AdministratorReportDetailScreen({
    required this.repository,
    required this.reportId,
    required this.onUnauthorized,
    super.key,
  });

  final AdminRepository repository;
  final String reportId;
  final VoidCallback onUnauthorized;

  @override
  State<AdministratorReportDetailScreen> createState() =>
      _AdministratorReportDetailScreenState();
}

class _AdministratorReportDetailScreenState
    extends State<AdministratorReportDetailScreen> {
  AdminReport? _report;
  bool _loading = true;
  bool _updating = false;
  AdminRepositoryErrorType? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await widget.repository.fetchReport(widget.reportId);
      if (mounted) {
        setState(() {
          _report = report;
          _loading = false;
        });
      }
    } on AdminRepositoryException catch (error) {
      if (!mounted) return;
      if (error.type == AdminRepositoryErrorType.unauthorized) {
        widget.onUnauthorized();
        Navigator.of(context).pop(_changed);
        return;
      }
      setState(() {
        _error = error.type;
        _loading = false;
      });
    }
  }

  Future<void> _update(AdminReportStatus status) async {
    if (_updating) return;
    setState(() {
      _updating = true;
      _error = null;
    });
    try {
      final report = await widget.repository.updateStatus(
        widget.reportId,
        status,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _updating = false;
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report marked ${status.label.toLowerCase()}.')),
      );
    } on AdminRepositoryException catch (error) {
      if (!mounted) return;
      if (error.type == AdminRepositoryErrorType.unauthorized) {
        widget.onUnauthorized();
        Navigator.of(context).pop(_changed);
        return;
      }
      setState(() {
        _error = error.type;
        _updating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F6),
        appBar: AppBar(
          title: const Text('Report details'),
          backgroundColor: const Color(0xFF176B5B),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    key: Key('admin-report-detail-loading'),
                  ),
                )
              : _error != null && _report == null
              ? _DetailError(error: _error!, onRetry: _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _ReportDetails(
                    report: _report!,
                    updating: _updating,
                    updateError: _error,
                    onUpdate: _update,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ReportDetails extends StatelessWidget {
  const _ReportDetails({
    required this.report,
    required this.updating,
    required this.updateError,
    required this.onUpdate,
  });
  final AdminReport report;
  final bool updating;
  final AdminRepositoryErrorType? updateError;
  final ValueChanged<AdminReportStatus> onUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          report.resource.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(report.status.label)),
            Chip(label: Text(report.reason.label)),
          ],
        ),
        _InfoCard(
          title: 'Report details',
          value: report.details ?? 'No additional details.',
        ),
        _InfoCard(title: 'Resource ID', value: report.resource.id),
        _InfoCard(title: 'Category', value: report.resource.category),
        _InfoCard(title: 'Address', value: report.resource.fullAddress),
        _InfoCard(
          title: 'Submitted',
          value: _formatDateTime(report.submittedAtUtc),
        ),
        _InfoCard(
          title: 'Reviewer',
          value: report.reviewingAdministratorId ?? 'Not reviewed yet',
        ),
        _InfoCard(
          title: 'Review time',
          value: report.reviewedAtUtc == null
              ? 'Not reviewed yet'
              : _formatDateTime(report.reviewedAtUtc!),
        ),
        if (updateError != null) ...[
          const SizedBox(height: 8),
          Text(
            updateError == AdminRepositoryErrorType.validation
                ? 'That status transition is not allowed.'
                : 'Unable to update this report. Try again.',
            key: const Key('admin-status-update-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (report.status.allowedTransitions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Update status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.status.allowedTransitions
                .map(
                  (status) => FilledButton(
                    key: Key('admin-status-${status.apiCode}'),
                    onPressed: updating ? null : () => onUpdate(status),
                    child: Text(status.label),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (updating)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                key: Key('admin-status-updating'),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    ),
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.error, required this.onRetry});
  final AdminRepositoryErrorType error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56),
          const SizedBox(height: 12),
          Text(
            error == AdminRepositoryErrorType.notFound
                ? 'This report was not found.'
                : 'Unable to load this report.',
          ),
          if (error != AdminRepositoryErrorType.notFound) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    ),
  );
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.month}/${local.day}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
