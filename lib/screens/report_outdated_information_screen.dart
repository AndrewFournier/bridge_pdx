import 'package:flutter/material.dart';

import '../models/community_resource.dart';
import '../models/outdated_information_report.dart';
import '../repositories/report_repository.dart';

class ReportOutdatedInformationScreen extends StatefulWidget {
  const ReportOutdatedInformationScreen({
    required this.resource,
    required this.repository,
    super.key,
  });

  final CommunityResource resource;
  final ReportRepository repository;

  @override
  State<ReportOutdatedInformationScreen> createState() =>
      _ReportOutdatedInformationScreenState();
}

class _ReportOutdatedInformationScreenState
    extends State<ReportOutdatedInformationScreen> {
  static const _detailsLimit = 500;

  final _detailsController = TextEditingController();
  ReportReason? _selectedReason;
  bool _showReasonError = false;
  bool _isSubmitting = false;
  String? _submissionError;
  int _remainingCharacters = _detailsLimit;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_selectedReason == null) {
      setState(() => _showReasonError = true);
      return;
    }

    final details = _detailsController.text.trim();
    final report = OutdatedInformationReport(
      resourceId: widget.resource.id,
      reason: _selectedReason!,
      details: details.isEmpty ? null : details,
    );
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      final submitted = await widget.repository.submitReport(report);
      if (mounted) Navigator.of(context).pop(submitted);
    } on ReportRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionError = switch (error.type) {
          ReportRepositoryErrorType.validation =>
            'Please review the report details and try again.',
          ReportRepositoryErrorType.notFound =>
            'This resource is no longer available for reporting.',
          ReportRepositoryErrorType.rateLimited =>
            'Too many reports were submitted. Please wait and try again.',
          ReportRepositoryErrorType.connection =>
            'Unable to submit the report. Check your connection and try again.',
          ReportRepositoryErrorType.server ||
          ReportRepositoryErrorType.invalidResponse =>
            'The report could not be submitted right now. Please try again.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionError =
            'Unable to submit the report. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report outdated information'),
        backgroundColor: const Color(0xFF176B5B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const Key('report-form-scroll'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.resource.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Reports are submitted anonymously. BridgePDX does not ask for your name, email address, or phone number on this form.',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'What needs updating? *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReportReason.values
                    .map(
                      (reason) => ChoiceChip(
                        key: Key('report-reason-${reason.name}'),
                        label: Text(reason.label),
                        selected: _selectedReason == reason,
                        onSelected: (_) => setState(() {
                          _selectedReason = reason;
                          _showReasonError = false;
                        }),
                      ),
                    )
                    .toList(growable: false),
              ),
              if (_showReasonError)
                Text(
                  'Select a reason before submitting.',
                  key: const Key('report-reason-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('report-details-field'),
                controller: _detailsController,
                maxLength: _detailsLimit,
                maxLines: 5,
                onChanged: (value) => setState(
                  () => _remainingCharacters = _detailsLimit - value.length,
                ),
                decoration: InputDecoration(
                  labelText: 'Additional details (optional)',
                  hintText: 'Describe what should be corrected.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  counterText: '$_remainingCharacters characters remaining',
                ),
              ),
              if (_submissionError != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _submissionError!,
                    key: const Key('report-submission-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('submit-report-button'),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox.square(
                        key: Key('report-submitting-indicator'),
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_isSubmitting ? 'Submitting…' : 'Submit report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
