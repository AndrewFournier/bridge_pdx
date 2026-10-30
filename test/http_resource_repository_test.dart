import 'package:bridge_pdx/config/api_configuration.dart';
import 'package:bridge_pdx/data/resource_categories.dart';
import 'package:bridge_pdx/models/resource_query.dart';
import 'package:bridge_pdx/repositories/http_resource_repository.dart';
import 'package:bridge_pdx/repositories/resource_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'builds encoded server-side query parameters for combined filters',
    () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response('[]', 200);
      });
      final repository = HttpResourceRepository(
        baseUri: Uri.parse('http://127.0.0.1:5080'),
        client: client,
      );

      await repository.fetchResources(
        query: const ResourceQuery(category: foodCategory, zipCode: '97201'),
        openNow: true,
        wheelchairAccessible: true,
      );

      expect(requestedUri.path, '/api/resources');
      expect(requestedUri.queryParameters, {
        'category': 'Food',
        'zipCode': '97201',
        'openNow': 'true',
        'wheelchairAccessible': 'true',
      });
    },
  );

  test('maps malformed response to a controlled repository error', () async {
    final repository = HttpResourceRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      client: MockClient((_) async => http.Response('{bad json', 200)),
    );

    await expectLater(
      repository.fetchResources(query: const ResourceQuery()),
      throwsA(
        isA<ResourceRepositoryException>().having(
          (error) => error.type,
          'type',
          ResourceRepositoryErrorType.invalidResponse,
        ),
      ),
    );
  });

  test('maps server failures to a controlled repository error', () async {
    final repository = HttpResourceRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );

    await expectLater(
      repository.fetchResources(query: const ResourceQuery()),
      throwsA(
        isA<ResourceRepositoryException>().having(
          (error) => error.type,
          'type',
          ResourceRepositoryErrorType.server,
        ),
      ),
    );
  });

  test('maps network failures to a controlled repository error', () async {
    final repository = HttpResourceRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      client: MockClient((request) async {
        throw http.ClientException('Connection refused', request.url);
      }),
    );

    await expectLater(
      repository.fetchResources(query: const ResourceQuery()),
      throwsA(
        isA<ResourceRepositoryException>().having(
          (error) => error.type,
          'type',
          ResourceRepositoryErrorType.connection,
        ),
      ),
    );
  });

  test('requests an encoded resource detail endpoint', () async {
    late Uri requestedUri;
    final repository = HttpResourceRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response('', 404);
      }),
    );

    await expectLater(
      repository.fetchResource('sample resource/1'),
      throwsA(
        isA<ResourceRepositoryException>().having(
          (error) => error.type,
          'type',
          ResourceRepositoryErrorType.notFound,
        ),
      ),
    );
    expect(requestedUri.path, '/api/resources/sample%20resource%2F1');
  });

  test('uses platform-specific development API hosts', () {
    expect(
      ApiConfiguration.developmentBaseUri(
        platform: TargetPlatform.android,
      ).host,
      '10.0.2.2',
    );
    expect(
      ApiConfiguration.developmentBaseUri(platform: TargetPlatform.iOS).host,
      '127.0.0.1',
    );
  });
}
