import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/admin_models.dart';
import '../storage/admin_token_store.dart';
import 'admin_repository.dart';

class HttpAdminRepository implements AdminRepository {
  HttpAdminRepository({
    required this.baseUri,
    required this.tokenStore,
    http.Client? client,
    DateTime Function()? now,
    this.requestTimeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _now = now ?? DateTime.now;

  final Uri baseUri;
  final AdminTokenStore tokenStore;
  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _now;
  final Duration requestTimeout;

  @override
  Future<void> login({required String email, required String password}) async {
    final response = await _send(
      () => _client.post(
        _endpoint('api/admin/auth/login'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
    );
    if (response.statusCode == 401) {
      throw const AdminRepositoryException(
        AdminRepositoryErrorType.invalidCredentials,
      );
    }
    if (response.statusCode == 429) {
      throw const AdminRepositoryException(
        AdminRepositoryErrorType.rateLimited,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AdminRepositoryException(AdminRepositoryErrorType.server);
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final token = StoredAdminToken(
        accessToken: json['accessToken'] as String,
        expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String).toUtc(),
      );
      if (token.accessToken.isEmpty) throw const FormatException();
      await tokenStore.write(token);
    } catch (error) {
      if (error is AdminRepositoryException) rethrow;
      throw const AdminRepositoryException(
        AdminRepositoryErrorType.invalidResponse,
      );
    }
  }

  @override
  Future<bool> hasValidSession() async {
    final token = await tokenStore.read();
    if (token == null) return false;
    if (!token.expiresAtUtc.isAfter(_now().toUtc())) {
      await tokenStore.clear();
      return false;
    }
    return true;
  }

  @override
  Future<AdministratorProfile> getMe() async {
    final response = await _authenticatedGet('api/admin/auth/me');
    return _parse(() => AdministratorProfile.fromJson(_object(response.body)));
  }

  @override
  Future<AdminReportPage> fetchReports(AdminReportFilter filter) async {
    final parameters = <String, String>{
      'page': filter.page.toString(),
      'pageSize': filter.pageSize.toString(),
      if (filter.status != null) 'status': filter.status!.apiCode,
      if (filter.reason != null) 'reason': filter.reason!.apiCode,
      if (filter.resourceId?.trim().isNotEmpty ?? false)
        'resourceId': filter.resourceId!.trim(),
      if (filter.submittedFromUtc != null)
        'submittedFromUtc': filter.submittedFromUtc!.toUtc().toIso8601String(),
      if (filter.submittedToUtc != null)
        'submittedToUtc': filter.submittedToUtc!.toUtc().toIso8601String(),
    };
    final response = await _authenticatedGet(
      'api/admin/reports',
      queryParameters: parameters,
    );
    return _parse(() {
      final json = _object(response.body);
      final items = json['items'] as List<dynamic>;
      return AdminReportPage(
        items: items
            .map((item) => AdminReport.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        totalCount: json['totalCount'] as int,
      );
    });
  }

  @override
  Future<AdminReport> fetchReport(String id) async {
    final response = await _authenticatedGet(
      'api/admin/reports/${Uri.encodeComponent(id)}',
    );
    return _parse(() => AdminReport.fromJson(_object(response.body)));
  }

  @override
  Future<AdminReport> updateStatus(String id, AdminReportStatus status) async {
    final response = await _authenticatedRequest(() async {
      final token = await _validToken();
      return _client.patch(
        _endpoint('api/admin/reports/${Uri.encodeComponent(id)}/status'),
        headers: {
          'Authorization': 'Bearer ${token.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status.apiCode}),
      );
    });
    return _parse(() => AdminReport.fromJson(_object(response.body)));
  }

  Future<http.Response> _authenticatedGet(
    String path, {
    Map<String, String>? queryParameters,
  }) => _authenticatedRequest(() async {
    final token = await _validToken();
    return _client.get(
      _endpoint(path, queryParameters: queryParameters),
      headers: {'Authorization': 'Bearer ${token.accessToken}'},
    );
  });

  Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function() request,
  ) async {
    final response = await _send(request);
    if (response.statusCode == 401) {
      await tokenStore.clear();
      throw const AdminRepositoryException(
        AdminRepositoryErrorType.unauthorized,
      );
    }
    if (response.statusCode == 400) {
      throw const AdminRepositoryException(AdminRepositoryErrorType.validation);
    }
    if (response.statusCode == 404) {
      throw const AdminRepositoryException(AdminRepositoryErrorType.notFound);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AdminRepositoryException(AdminRepositoryErrorType.server);
    }
    return response;
  }

  Future<StoredAdminToken> _validToken() async {
    final token = await tokenStore.read();
    if (token == null || !token.expiresAtUtc.isAfter(_now().toUtc())) {
      await tokenStore.clear();
      throw const AdminRepositoryException(
        AdminRepositoryErrorType.unauthorized,
      );
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(requestTimeout);
    } on AdminRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const AdminRepositoryException(AdminRepositoryErrorType.connection);
    } on SocketException {
      throw const AdminRepositoryException(AdminRepositoryErrorType.connection);
    } on http.ClientException {
      throw const AdminRepositoryException(AdminRepositoryErrorType.connection);
    }
  }

  T _parse<T>(T Function() parser) {
    try {
      return parser();
    } catch (_) {
      throw const AdminRepositoryException(
        AdminRepositoryErrorType.invalidResponse,
      );
    }
  }

  Map<String, dynamic> _object(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  Uri _endpoint(String path, {Map<String, String>? queryParameters}) {
    final basePath = baseUri.path.endsWith('/')
        ? baseUri.path
        : '${baseUri.path}/';
    return baseUri.replace(
      path: '$basePath$path',
      queryParameters: queryParameters,
    );
  }

  @override
  Future<void> logout() => tokenStore.clear();

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
