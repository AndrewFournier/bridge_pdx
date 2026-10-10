import '../models/community_resource.dart';
import '../models/resource_query.dart';

abstract interface class ResourceRepository {
  Future<List<CommunityResource>> fetchResources({
    required ResourceQuery query,
    bool? openNow,
    bool? wheelchairAccessible,
  });

  Future<CommunityResource> fetchResource(String id);

  void close();
}

enum ResourceRepositoryErrorType {
  connection,
  server,
  notFound,
  invalidResponse,
}

class ResourceRepositoryException implements Exception {
  const ResourceRepositoryException(this.type);

  final ResourceRepositoryErrorType type;
}
