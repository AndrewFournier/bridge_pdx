import 'package:bridge_pdx/data/sample_resources.dart';
import 'package:bridge_pdx/models/community_resource.dart';
import 'package:bridge_pdx/models/resource_query.dart';
import 'package:bridge_pdx/repositories/resource_repository.dart';

typedef FetchResourcesCallback =
    Future<List<CommunityResource>> Function(
      ResourceQuery query,
      bool? openNow,
      bool? wheelchairAccessible,
    );

class FakeResourceRepository implements ResourceRepository {
  FakeResourceRepository({this.onFetchResources, this.onFetchResource});

  final FetchResourcesCallback? onFetchResources;
  final Future<CommunityResource> Function(String id)? onFetchResource;
  final List<({ResourceQuery query, bool? openNow, bool? wheelchairAccessible})>
  collectionRequests = [];
  final List<String> detailRequests = [];
  bool isClosed = false;

  @override
  Future<List<CommunityResource>> fetchResources({
    required ResourceQuery query,
    bool? openNow,
    bool? wheelchairAccessible,
  }) async {
    collectionRequests.add((
      query: query,
      openNow: openNow,
      wheelchairAccessible: wheelchairAccessible,
    ));
    if (onFetchResources != null) {
      return onFetchResources!(query, openNow, wheelchairAccessible);
    }
    return query.apply(
      sampleResources,
      openNow: openNow ?? false,
      wheelchairAccessible: wheelchairAccessible ?? false,
    );
  }

  @override
  Future<CommunityResource> fetchResource(String id) async {
    detailRequests.add(id);
    if (onFetchResource != null) return onFetchResource!(id);
    return sampleResources.firstWhere(
      (resource) => resource.id == id,
      orElse: () => throw const ResourceRepositoryException(
        ResourceRepositoryErrorType.notFound,
      ),
    );
  }

  @override
  void close() {
    isClosed = true;
  }
}
