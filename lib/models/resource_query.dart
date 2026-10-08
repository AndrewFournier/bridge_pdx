import 'community_resource.dart';
import 'resource_category.dart';

class ResourceQuery {
  const ResourceQuery({this.category, this.zipCode});

  final ResourceCategory? category;
  final String? zipCode;

  String get title {
    if (category != null && zipCode != null) {
      return '${category!.name} in $zipCode';
    }
    if (category != null) return '${category!.name} Resources';
    return 'Resources for $zipCode';
  }

  String get listKey => '${category?.id ?? 'all'}-${zipCode ?? 'all'}';

  List<CommunityResource> apply(
    Iterable<CommunityResource> resources, {
    bool openNow = false,
    bool wheelchairAccessible = false,
  }) {
    return resources
        .where((resource) {
          final matchesCategory =
              category == null || resource.category.id == category!.id;
          final matchesZip = zipCode == null || resource.zipCode == zipCode;
          final matchesOpen = !openNow || resource.isOpenNow;
          final matchesAccessibility =
              !wheelchairAccessible || resource.isWheelchairAccessible;
          return matchesCategory &&
              matchesZip &&
              matchesOpen &&
              matchesAccessibility;
        })
        .toList(growable: false);
  }
}
