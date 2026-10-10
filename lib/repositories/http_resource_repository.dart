import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/community_resource.dart';
import '../models/resource_query.dart';
import 'resource_repository.dart';

class HttpResourceRepository implements ResourceRepository {
  factory HttpResourceRepository({
    required Uri baseUri,
    http.Client? client,
    Duration requestTimeout = const Duration(seconds: 10),
  }) => HttpResourceRepository._(
    baseUri,
    client ?? http.Client(),
    client == null,
    requestTimeout,
  );

  HttpResourceRepository._(
    this._baseUri,
    this._client,
    this._ownsClient,
    this.requestTimeout,
  );

  final Uri _baseUri;
  final http.Client _client;
  final bool _ownsClient;
  final Duration requestTimeout;

  @override
  Future<List<CommunityResource>> fetchResources({
    required ResourceQuery query,
    bool? openNow,
    bool? wheelchairAccessible,
  }) async {
    final parameters = <String, String>{
      if (query.category != null) 'category': query.category!.name,
      if (query.zipCode != null) 'zipCode': query.zipCode!,
      if (openNow != null) 'openNow': openNow.toString(),
      if (wheelchairAccessible != null)
        'wheelchairAccessible': wheelchairAccessible.toString(),
    };
    final uri = _endpoint(
      'api/resources',
      queryParameters: parameters.isEmpty ? null : parameters,
    );
    final response = await _get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ResourceRepositoryException(
        ResourceRepositoryErrorType.server,
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List<dynamic>) throw const FormatException();
      return decoded
          .map((item) {
            if (item is! Map<String, dynamic>) throw const FormatException();
            return CommunityResource.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException {
      throw const ResourceRepositoryException(
        ResourceRepositoryErrorType.invalidResponse,
      );
    }
  }

  @override
  Future<CommunityResource> fetchResource(String id) async {
    final response = await _get(_endpoint('api/resources/$id'));
    if (response.statusCode == 404) {
      throw const ResourceRepositoryException(
        ResourceRepositoryErrorType.notFound,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ResourceRepositoryException(
        ResourceRepositoryErrorType.server,
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return CommunityResource.fromJson(decoded);
    } on FormatException {
      throw const ResourceRepositoryException(
        ResourceRepositoryErrorType.invalidResponse,
      );
    }
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri).timeout(requestTimeout);
    } on TimeoutException {
      throw const ResourceRepositoryException(
        ResourceRepositoryErrorType.connection,
      );
    } on http.ClientException {
      throw const ResourceRepositoryException(
        ResourceRepositoryErrorType.connection,
      );
    } catch (_) {
      throw const ResourceRepositoryException(
        ResourceRepositoryErrorType.connection,
      );
    }
  }

  Uri _endpoint(String path, {Map<String, String>? queryParameters}) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';
    return _baseUri.replace(
      path: '$basePath$path',
      queryParameters: queryParameters,
    );
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
