import 'package:flutter/material.dart';

import '../models/resource_category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({required this.category, required this.onTap, super.key});

  final ResourceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('category-${category.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: category.color.withValues(alpha: 0.12),
                foregroundColor: category.color,
                child: Icon(category.icon),
              ),
              const Spacer(),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Flexible(
                child: Text(
                  category.description,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(color: Colors.black54, height: 1.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
