import 'package:flutter/material.dart';

import '../data/sample_resources.dart';
import '../models/resource_query.dart';
import '../widgets/resource_card.dart';

class ResourceListScreen extends StatefulWidget {
  const ResourceListScreen({required this.query, super.key});

  final ResourceQuery query;

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  bool _openNow = false;
  bool _wheelchairAccessible = false;

  void _clearFilters() {
    setState(() {
      _openNow = false;
      _wheelchairAccessible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resources = widget.query.apply(
      sampleResources,
      openNow: _openNow,
      wheelchairAccessible: _wheelchairAccessible,
    );
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
                onOpenNowChanged: (value) => setState(() => _openNow = value),
                onWheelchairChanged: (value) =>
                    setState(() => _wheelchairAccessible = value),
                onClear: hasActiveFilters ? _clearFilters : null,
              ),
              const SizedBox(height: 12),
              if (resources.isEmpty)
                _EmptyState(
                  hasActiveFilters: hasActiveFilters,
                  hasZipCode: widget.query.zipCode != null,
                  onClearFilters: _clearFilters,
                )
              else
                ...resources.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ResourceCard(resource: resource),
                  ),
                ),
            ],
          ),
        ),
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
