import 'package:flutter/material.dart';

import '../models/community_resource.dart';

class ResourceCard extends StatelessWidget {
  const ResourceCard({required this.resource, required this.onTap, super.key});

  final CommunityResource resource;
  final VoidCallback onTap;

  void _showPendingMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('resource-${resource.id}'),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('resource-card-${resource.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(resource.description),
              const SizedBox(height: 6),
              Text(
                'Tap for full details',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      resource.isOpenNow ? Icons.check_circle : Icons.cancel,
                      size: 18,
                    ),
                    label: Text(
                      resource.isOpenNow ? 'Shown as open' : 'Shown as closed',
                    ),
                  ),
                  if (resource.isWheelchairAccessible)
                    const Chip(
                      avatar: Icon(Icons.accessible, size: 18),
                      label: Text('Wheelchair accessible'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _Detail(
                icon: Icons.location_on_outlined,
                label: resource.fullAddress,
              ),
              _Detail(
                icon: Icons.schedule,
                label: 'Sample hours: ${resource.hours}',
              ),
              _Detail(
                icon: Icons.accessible,
                label: resource.accessibilityInformation,
              ),
              _Detail(
                icon: Icons.fact_check_outlined,
                label: 'Eligibility: ${resource.eligibilitySummary}',
              ),
              _Detail(
                icon: Icons.verified_outlined,
                label: 'Last verified: ${_formatDate(resource.lastVerified)}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showPendingMessage(
                      context,
                      'Phone integration will be added later. Sample number: ${resource.phoneNumber}',
                    ),
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showPendingMessage(
                      context,
                      'Map and directions integration will be added later.',
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
