import 'package:bridge_pdx/models/community_resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a complete API resource response', () {
    final resource = CommunityResource.fromJson(validResourceJson());

    expect(resource.id, 'api-food-1');
    expect(resource.category.name, 'Food');
    expect(resource.website, Uri.parse('https://api-food-1.example.org'));
    expect(resource.lastVerified, DateTime(2026, 9, 15));
    expect(resource.servicesOffered, ['Sample grocery pickup']);
    expect(resource.isOpenNow, isTrue);
    expect(resource.isActive, isTrue);
  });

  test('rejects malformed API resource values', () {
    final json = validResourceJson()..['isOpenNow'] = 'yes';

    expect(() => CommunityResource.fromJson(json), throwsFormatException);
  });
}

Map<String, dynamic> validResourceJson({
  String id = 'api-food-1',
  String name = 'Sample API Food Desk',
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'category': 'Food',
  'description': 'A fictional API resource used only for testing.',
  'streetAddress': '101 Sample Street',
  'city': 'Portland',
  'state': 'OR',
  'zipCode': '97201',
  'phone': '(503) 555-0101',
  'website': 'https://$id.example.org',
  'hours': 'Sample hours only',
  'eligibility': 'Sample eligibility only',
  'documentsToBring': ['Sample ID'],
  'servicesOffered': ['Sample grocery pickup'],
  'languagesSupported': ['English'],
  'accessibilityInformation': 'Sample accessibility information.',
  'isOpenNow': true,
  'isWheelchairAccessible': true,
  'lastVerified': '2026-09-15',
  'isActive': true,
};
