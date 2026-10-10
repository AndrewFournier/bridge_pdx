import 'package:flutter/material.dart';

import '../models/community_resource.dart';
import '../models/resource_query.dart';
import '../repositories/resource_repository.dart';
import '../widgets/resource_card.dart';
import 'resource_detail_screen.dart';

class ResourceListScreen extends StatefulWidget {
  const ResourceListScreen({
    required this.query,
    required this.repository,
    super.key,
  });

  final ResourceQuery query;
  final ResourceRepository repository;

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  bool _openNow = false;
  bool _wheelchairAccessible = false;
  bool _isLoading = true;
  List<CommunityResource> _resources = const [];
  ResourceRepositoryErrorType? _errorType;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _requestGeneration++;
    super.dispose();
  }

  Future<void> _loadResources() async {
    final generation = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _errorType = null;
    });

    try {
      final resources = await widget.repository.fetchResources(
        query: widget.query,
        openNow: _openNow ? true : null,
        wheelchairAccessible: _wheelchairAccessible ? true : null,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _resources = resources;
        _isLoading = false;
      });
    } on ResourceRepositoryException catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _resources = const [];
        _isLoading = false;
        _errorType = error.type;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _resources = const [];
        _isLoading = false;
        _errorType = ResourceRepositoryErrorType.connection;
      });
    }
  }

  void _setOpenNow(bool value) {
    if (_openNow == value) return;
    setState(() => _openNow = value);
    _loadResources();
  }

  void _setWheelchairAccessible(bool value) {
    if (_wheelchairAccessible == value) return;
    setState(() => _wheelchairAccessible = value);
    _loadResources();
  }

  void _clearFilters() {
    if (!_openNow && !_wheelchairAccessible) return;
    setState(() {
      _openNow = false;
      _wheelchairAccessible = false;
    });
    _loadResources();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _openNow || _wheelchairAccessible;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: Text(widget.query.title),
        backgroundColor: const Color(0xFF176B5B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: Key('resource-list-${widget.query.listKey}'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SampleDataNotice(),
              const SizedBox(height: 12),
              _ResourceFilters(
                openNow: _openNow,
                wheelchairAccessible: _wheelchairAccessible,
                onOpenNowChanged: _setOpenNow,
                onWheelchairChanged: _setWheelchairAccessible,
                onClear: hasActiveFilters ? _clearFilters : null,
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  key: Key('resource-list-loading'),
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorType != null)
                _ResourceErrorState(
                  isConnectionError:
                      _errorType == ResourceRepositoryErrorType.connection,
                  onRetry: _loadResources,
                )
              else if (_resources.isEmpty)
                _EmptyState(
                  hasActiveFilters: hasActiveFilters,
                  hasZipCode: widget.query.zipCode != null,
                  onClearFilters: _clearFilters,
                )
              else
                ..._resources.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ResourceCard(
                      resource: resource,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ResourceDetailScreen(
                            resourceId: resource.id,
                            repository: widget.repository,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceErrorState extends StatelessWidget {
  const _ResourceErrorState({
    required this.isConnectionError,
    required this.onRetry,
  });

  final bool isConnectionError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('resource-list-error'),
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            isConnectionError
                ? 'Unable to connect to BridgePDX'
                : 'Resources are temporarily unavailable',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Check that the local API is running, then try again.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('resource-list-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ResourceFilters extends StatelessWidget {
  const _ResourceFilters({
    required this.openNow,
    required this.wheelchairAccessible,
    required this.onOpenNowChanged,
    required this.onWheelchairChanged,
    required this.onClear,
  });

  final bool openNow;
  final bool wheelchairAccessible;
  final ValueChanged<bool> onOpenNowChanged;
  final ValueChanged<bool> onWheelchairChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          key: const Key('filter-open-now'),
          selected: openNow,
          onSelected: onOpenNowChanged,
          avatar: const Icon(Icons.schedule, size: 18),
          label: const Text('Open now'),
        ),
        FilterChip(
          key: const Key('filter-wheelchair-accessible'),
          selected: wheelchairAccessible,
          onSelected: onWheelchairChanged,
          avatar: const Icon(Icons.accessible, size: 18),
          label: const Text('Wheelchair accessible'),
        ),
        if (onClear != null)
          TextButton.icon(
            key: const Key('clear-filters-button'),
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            label: const Text('Clear filters'),
          ),
      ],
    );
  }
}

class _SampleDataNotice extends StatelessWidget {
  const _SampleDataNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
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
                'Sample data — These fictional entries are for demonstration only and are not real or verified organizations.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasActiveFilters,
    required this.hasZipCode,
    required this.onClearFilters,
  });

  final bool hasActiveFilters;
  final bool hasZipCode;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters
                ? 'No resources match these filters'
                : 'No sample resources found',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters
                ? 'Clear one or more filters to see other sample resources.'
                : 'Go back and try another ZIP code or category.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (hasActiveFilters)
            OutlinedButton(
              key: const Key('empty-clear-filters-button'),
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            )
          else if (hasZipCode)
            FilledButton.icon(
              key: const Key('try-another-zip-button'),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Try another ZIP code'),
            ),
        ],
      ),
    );
  }
}
