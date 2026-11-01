import 'dart:convert';

import 'package:bridge_pdx/models/admin_models.dart';
import 'package:bridge_pdx/repositories/admin_repository.dart';
import 'package:bridge_pdx/repositories/http_admin_repository.dart';
import 'package:bridge_pdx/storage/admin_token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_admin_repository.dart';

void main() {
  test('successful login stores token and expiration in token store', () async {
    final store = FakeAdminTokenStore();
    final repository = HttpAdminRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      tokenStore: store,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'accessToken': 'secure-test-token',
            'expiresAtUtc': '2026-10-30T20:15:00Z',
            'tokenType': 'Bearer',
          }),
          200,
        ),
      ),
    );

    await repository.login(
      email: ' admin@example.invalid ',
      password: 'secret',
    );

    expect(store.writes, 1);
    expect(store.token!.accessToken, 'secure-test-token');
    expect(store.token!.expiresAtUtc, DateTime.utc(2026, 10, 30, 20, 15));
  });

  test('failed login does not store credentials or token', () async {
    final store = FakeAdminTokenStore();
    final repository = HttpAdminRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      tokenStore: store,
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    await expectLater(
      repository.login(email: 'admin@example.invalid', password: 'wrong'),
      throwsA(
        isA<AdminRepositoryException>().having(
          (error) => error.type,
          'type',
          AdminRepositoryErrorType.invalidCredentials,
        ),
      ),
    );
    expect(store.token, isNull);
    expect(store.writes, 0);
  });

  test('adds bearer authorization and all report filters', () async {
    final store = FakeAdminTokenStore()
      ..token = StoredAdminToken(
        accessToken: 'admin-token',
        expiresAtUtc: DateTime.utc(2026, 11),
      );
    late http.Request request;
    final repository = HttpAdminRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      tokenStore: store,
      now: () => DateTime.utc(2026, 10, 30),
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode({'items': [], 'page': 2, 'pageSize': 10, 'totalCount': 0}),
          200,
        );
      }),
    );

    await repository.fetchReports(
      AdminReportFilter(
        page: 2,
        pageSize: 10,
        status: AdminReportStatus.pending,
        reason: AdminReportReason.incorrectHours,
        resourceId: 'food-1',
        submittedFromUtc: DateTime.utc(2026, 10, 1),
        submittedToUtc: DateTime.utc(2026, 10, 30),
      ),
    );

    expect(request.headers['authorization'], 'Bearer admin-token');
    expect(request.url.queryParameters, {
      'page': '2',
      'pageSize': '10',
      'status': 'pending',
      'reason': 'incorrect_hours',
      'resourceId': 'food-1',
      'submittedFromUtc': '2026-10-01T00:00:00.000Z',
      'submittedToUtc': '2026-10-30T00:00:00.000Z',
    });
  });

  test('expired token signs out before making a request', () async {
    var requests = 0;
    final store = FakeAdminTokenStore()
      ..token = StoredAdminToken(
        accessToken: 'expired',
        expiresAtUtc: DateTime.utc(2026, 10, 29),
      );
    final repository = HttpAdminRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      tokenStore: store,
      now: () => DateTime.utc(2026, 10, 30),
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      repository.getMe(),
      throwsA(isA<AdminRepositoryException>()),
    );
    expect(requests, 0);
    expect(store.clears, 1);
    expect(store.token, isNull);
  });

  test('401 clears the stored token and signs out', () async {
    final store = FakeAdminTokenStore()
      ..token = StoredAdminToken(
        accessToken: 'rejected',
        expiresAtUtc: DateTime.utc(2026, 11),
      );
    final repository = HttpAdminRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      tokenStore: store,
      now: () => DateTime.utc(2026, 10, 30),
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    await expectLater(
      repository.getMe(),
      throwsA(
        isA<AdminRepositoryException>().having(
          (error) => error.type,
          'type',
          AdminRepositoryErrorType.unauthorized,
        ),
      ),
    );
    expect(store.token, isNull);
    expect(store.clears, 1);
  });

  test('logout clears secure token state', () async {
    final store = FakeAdminTokenStore()
      ..token = StoredAdminToken(
        accessToken: 'token',
        expiresAtUtc: DateTime.utc(2026, 11),
      );
    final repository = HttpAdminRepository(
      baseUri: Uri.parse('http://127.0.0.1:5080'),
      tokenStore: store,
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    await repository.logout();
    expect(store.token, isNull);
    expect(store.clears, 1);
  });
}
