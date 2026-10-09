import 'package:flutter/material.dart';

import '../models/community_resource.dart';
import '../models/outdated_information_report.dart';

class ReportOutdatedInformationScreen extends StatefulWidget {
  const ReportOutdatedInformationScreen({required this.resource, super.key});

  final CommunityResource resource;

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

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedReason == null) {
      setState(() => _showReasonError = true);
      return;
    }

    final report = OutdatedInformationReport(
      resourceId: widget.resource.id,
      reason: _selectedReason!,
      details: _detailsController.text.trim(),
    );
    Navigator.of(context).pop(report);
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
                    'Anonymous prototype form — no identity is collected. Reports are not transmitted or permanently saved yet.',
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
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  hintText: 'Describe what should be corrected.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('submit-report-button'),
                onPressed: _submit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Submit report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
