import 'package:flutter/material.dart';

import '../models/resource_category.dart';

const foodCategory = ResourceCategory(
  id: 'food',
  name: 'Food',
  description: 'Food banks and free meals',
  icon: Icons.restaurant,
  color: Color(0xFFE67E22),
);
const housingCategory = ResourceCategory(
  id: 'housing',
  name: 'Housing',
  description: 'Shelters and housing assistance',
  icon: Icons.home,
  color: Color(0xFF3F70AE),
);
const healthcareCategory = ResourceCategory(
  id: 'healthcare',
  name: 'Healthcare',
  description: 'Medical and mental health services',
  icon: Icons.local_hospital,
  color: Color(0xFFB64747),
);
const familySupportCategory = ResourceCategory(
  id: 'family-support',
  name: 'Family Support',
  description: 'Childcare and family resources',
  icon: Icons.family_restroom,
  color: Color(0xFF8654A3),
);
const employmentCategory = ResourceCategory(
  id: 'employment',
  name: 'Employment',
  description: 'Jobs and career assistance',
  icon: Icons.work,
  color: Color(0xFF2F7D4A),
);
const transportationCategory = ResourceCategory(
  id: 'transportation',
  name: 'Transportation',
  description: 'Transit and transportation help',
  icon: Icons.directions_bus,
  color: Color(0xFF397E8C),
);

const resourceCategories = <ResourceCategory>[
  foodCategory,
  housingCategory,
  healthcareCategory,
  familySupportCategory,
  employmentCategory,
  transportationCategory,
];
