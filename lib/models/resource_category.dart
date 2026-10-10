import 'package:flutter/material.dart';

class ResourceCategory {
  const ResourceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  factory ResourceCategory.fromApiName(String name) {
    return switch (name.toLowerCase()) {
      'food' => const ResourceCategory(
        id: 'food',
        name: 'Food',
        description: 'Food banks and free meals',
        icon: Icons.restaurant,
        color: Color(0xFFE67E22),
      ),
      'housing' => const ResourceCategory(
        id: 'housing',
        name: 'Housing',
        description: 'Shelters and housing assistance',
        icon: Icons.home,
        color: Color(0xFF3F70AE),
      ),
      'healthcare' => const ResourceCategory(
        id: 'healthcare',
        name: 'Healthcare',
        description: 'Medical and mental health services',
        icon: Icons.local_hospital,
        color: Color(0xFFB64747),
      ),
      'family support' => const ResourceCategory(
        id: 'family-support',
        name: 'Family Support',
        description: 'Childcare and family resources',
        icon: Icons.family_restroom,
        color: Color(0xFF8654A3),
      ),
      'employment' => const ResourceCategory(
        id: 'employment',
        name: 'Employment',
        description: 'Jobs and career assistance',
        icon: Icons.work,
        color: Color(0xFF2F7D4A),
      ),
      'transportation' => const ResourceCategory(
        id: 'transportation',
        name: 'Transportation',
        description: 'Transit and transportation help',
        icon: Icons.directions_bus,
        color: Color(0xFF397E8C),
      ),
      _ => ResourceCategory(
        id: name.toLowerCase().replaceAll(' ', '-'),
        name: name,
        description: 'Community resources',
        icon: Icons.category_outlined,
        color: const Color(0xFF176B5B),
      ),
    };
  }
}
