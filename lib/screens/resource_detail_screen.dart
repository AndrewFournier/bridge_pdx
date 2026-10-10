import 'package:flutter/material.dart';

import '../models/community_resource.dart';
import '../models/outdated_information_report.dart';
import '../repositories/resource_repository.dart';
import '../repositories/report_repository.dart';
import '../widgets/detail_section.dart';
import 'report_outdated_information_screen.dart';

class ResourceDetailScreen extends StatefulWidget {
  const ResourceDetailScreen({
    required this.resourceId,
    required this.repository,
    required this.reportRepository,
    super.key,
  });

  final String resourceId;
  final ResourceRepository repository;
  final ReportRepository reportRepository;

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  CommunityResource? _resource;
  ResourceRepositoryErrorType? _errorType;
  bool _isLoading = true;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadResource();
  }

  @override
  void dispose() {
    _requestGeneration++;
    super.dispose();
  }

  Future<void> _loadResource() async {
    final generation = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _errorType = null;
    });
    try {
      final resource = await widget.repository.fetchResource(widget.resourceId);
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _resource = resource;
        _isLoading = false;
      });
    } on ResourceRepositoryException catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _resource = null;
        _errorType = error.type;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _resource = null;
        _errorType = ResourceRepositoryErrorType.connection;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resource != null && !_isLoading) {
      return _ResourceDetailContent(
        resource: _resource!,
        reportRepository: widget.reportRepository,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Resource details'),
        backgroundColor: const Color(0xFF176B5B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(
                  key: Key('resource-detail-loading'),
                )
              : _DetailLoadError(
                  isNotFound:
                      _errorType == ResourceRepositoryErrorType.notFound,
                  onRetry: _loadResource,
                ),
        ),
      ),
    );
  }
}

class _DetailLoadError extends StatelessWidget {
  const _DetailLoadError({required this.isNotFound, required this.onRetry});

  final bool isNotFound;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key(
        isNotFound ? 'resource-detail-not-found' : 'resource-detail-error',
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNotFound ? Icons.search_off : Icons.cloud_off_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            isNotFound ? 'Resource not found' : 'Unable to load this resource',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isNotFound
                ? 'This listing may no longer be available.'
                : 'Check the connection to the local API and try again.',
            textAlign: TextAlign.center,
          ),
          if (!isNotFound) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('resource-detail-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResourceDetailContent extends StatelessWidget {
  const _ResourceDetailContent({
    required this.resource,
    required this.reportRepository,
  });

  final CommunityResource resource;
  final ReportRepository reportRepository;

  void _showPendingAction(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openReport(BuildContext context) async {
    final report = await Navigator.of(context).push<SubmittedResourceReport>(
      MaterialPageRoute<SubmittedResourceReport>(
        builder: (_) => ReportOutdatedInformationScreen(
          resource: resource,
          repository: reportRepository,
        ),
      ),
    );
    if (report == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('report-confirmation'),
        content: Text(
          'Thank you. Your ${report.reason.label.toLowerCase()} report was submitted for review.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Resource details'),
        backgroundColor: const Color(0xFF176B5B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: Key('resource-detail-${resource.id}'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                resource.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                resource.category.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sample data — not a real service listing. This fictional information is for demonstration only.',
                          key: Key('detail-sample-data-notice'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(resource.description),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionButton(
                    key: const Key('detail-call-button'),
                    icon: Icons.call,
                    label: 'Call',
                    onPressed: () => _showPendingAction(
                      context,
                      'Phone integration will be added later. Sample number: ${resource.phoneNumber}',
                    ),
                  ),
                  _ActionButton(
                    key: const Key('detail-directions-button'),
                    icon: Icons.directions,
                    label: 'Directions',
                    onPressed: () => _showPendingAction(
                      context,
                      'Map and directions integration will be added later.',
                    ),
                  ),
                  _ActionButton(
                    key: const Key('detail-website-button'),
                    icon: Icons.language,
                    label: 'Website',
                    onPressed: () => _showPendingAction(
                      context,
                      'Website integration will be added later. Sample site: ${resource.website}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DetailSection(
                title: 'Location',
                icon: Icons.location_on_outlined,
                child: Text(resource.fullAddress),
              ),
              DetailSection(
                title: 'Hours and status',
                icon: Icons.schedule,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.hours),
                    const SizedBox(height: 8),
                    Chip(
                      avatar: Icon(
                        resource.isOpenNow ? Icons.check_circle : Icons.cancel,
                        size: 18,
                      ),
                      label: Text(
                        resource.isOpenNow
                            ? 'Shown as open now'
                            : 'Shown as closed now',
                      ),
                    ),
                  ],
                ),
              ),
              DetailSection(
                title: 'Services offered',
                icon: Icons.volunteer_activism_outlined,
                child: _BulletList(items: resource.servicesOffered),
              ),
              DetailSection(
                title: 'Eligibility requirements',
                icon: Icons.fact_check_outlined,
                child: Text(resource.eligibilitySummary),
              ),
              DetailSection(
                title: 'Documents to bring',
                icon: Icons.description_outlined,
                child: _BulletList(items: resource.documentsToBring),
              ),
              DetailSection(
                title: 'Languages supported',
                icon: Icons.translate,
                child: _BulletList(items: resource.languagesSupported),
              ),
              DetailSection(
                title: 'Accessibility',
                icon: Icons.accessible,
                child: Text(resource.accessibilityInformation),
              ),
              DetailSection(
                title: 'Verification',
                icon: Icons.verified_outlined,
                child: Text(
                  'Last verified: ${_formatDate(resource.lastVerified)}',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('report-outdated-information-button'),
                onPressed: () => _openReport(context),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report outdated information'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
