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
    required this.isActive,
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
  final bool isActive;

  String get fullAddress => '$streetAddress, $city, $state $zipCode';

  factory CommunityResource.fromJson(Map<String, dynamic> json) {
    final website = Uri.tryParse(_requiredString(json, 'website'));
    final lastVerified = DateTime.tryParse(
      _requiredString(json, 'lastVerified'),
    );
    if (website == null || !website.hasScheme || lastVerified == null) {
      throw const FormatException('Invalid resource URL or date.');
    }

    return CommunityResource(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      category: ResourceCategory.fromApiName(_requiredString(json, 'category')),
      description: _requiredString(json, 'description'),
      streetAddress: _requiredString(json, 'streetAddress'),
      city: _requiredString(json, 'city'),
      state: _requiredString(json, 'state'),
      zipCode: _requiredString(json, 'zipCode'),
      phoneNumber: _requiredString(json, 'phone'),
      website: website,
      hours: _requiredString(json, 'hours'),
      eligibilitySummary: _requiredString(json, 'eligibility'),
      documentsToBring: _requiredStringList(json, 'documentsToBring'),
      servicesOffered: _requiredStringList(json, 'servicesOffered'),
      languagesSupported: _requiredStringList(json, 'languagesSupported'),
      accessibilityInformation: _requiredString(
        json,
        'accessibilityInformation',
      ),
      isOpenNow: _requiredBool(json, 'isOpenNow'),
      isWheelchairAccessible: _requiredBool(json, 'isWheelchairAccessible'),
      lastVerified: lastVerified,
      isActive: _requiredBool(json, 'isActive'),
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or invalid $key.');
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) throw FormatException('Missing or invalid $key.');
    return value;
  }

  static List<String> _requiredStringList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List<dynamic> || value.any((item) => item is! String)) {
      throw FormatException('Missing or invalid $key.');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}
