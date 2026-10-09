import 'resource_category.dart';

class CommunityResource {
  const CommunityResource({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phoneNumber,
    required this.website,
    required this.hours,
    required this.isOpenNow,
    required this.isWheelchairAccessible,
    required this.eligibilitySummary,
    required this.documentsToBring,
    required this.servicesOffered,
    required this.languagesSupported,
    required this.accessibilityInformation,
    required this.lastVerified,
  });

  final String id;
  final String name;
  final ResourceCategory category;
  final String description;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String phoneNumber;
  final Uri website;
  final String hours;
  final bool isOpenNow;
  final bool isWheelchairAccessible;
  final String eligibilitySummary;
  final List<String> documentsToBring;
  final List<String> servicesOffered;
  final List<String> languagesSupported;
  final String accessibilityInformation;
  final DateTime lastVerified;

  String get fullAddress => '$streetAddress, $city, $state $zipCode';
}
