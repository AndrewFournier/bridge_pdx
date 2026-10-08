import 'resource_category.dart';

class CommunityResource {
  const CommunityResource({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.zipCode,
    required this.phoneNumber,
    required this.hours,
    required this.isOpenNow,
    required this.isWheelchairAccessible,
    required this.eligibilitySummary,
    required this.accessibilityInformation,
    required this.lastVerified,
  });

  final String id;
  final String name;
  final ResourceCategory category;
  final String description;
  final String address;
  final String zipCode;
  final String phoneNumber;
  final String hours;
  final bool isOpenNow;
  final bool isWheelchairAccessible;
  final String eligibilitySummary;
  final String accessibilityInformation;
  final DateTime lastVerified;
}
