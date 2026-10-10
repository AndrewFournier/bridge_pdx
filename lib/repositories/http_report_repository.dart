import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/outdated_information_report.dart';
import 'report_repository.dart';

class HttpReportRepository implements ReportRepository {
  HttpReportRepository({required this.baseUri, http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final Uri baseUri;
  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<SubmittedResourceReport> submitReport(
    OutdatedInformationReport report,
  ) async {
    final endpoint = baseUri.resolve(
      'api/resources/${Uri.encodeComponent(report.resourceId)}/reports',
    );
    try {
      final response = await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'reason': report.reason.apiCode,
              'details': report.details,
            }),
          )
          .timeout(const Duration(seconds: 10));
      switch (response.statusCode) {
        case 201:
          return _parseResponse(response.body);
        case 400:
          throw const ReportRepositoryException(
            ReportRepositoryErrorType.validation,
          );
        case 404:
          throw const ReportRepositoryException(
            ReportRepositoryErrorType.notFound,
          );
        case 429:
          throw const ReportRepositoryException(
            ReportRepositoryErrorType.rateLimited,
          );
        default:
          throw const ReportRepositoryException(
            ReportRepositoryErrorType.server,
          );
      }
    } on ReportRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const ReportRepositoryException(
        ReportRepositoryErrorType.connection,
      );
    } on SocketException {
      throw const ReportRepositoryException(
        ReportRepositoryErrorType.connection,
      );
    } on http.ClientException {
      throw const ReportRepositoryException(
        ReportRepositoryErrorType.connection,
      );
    }
  }

  SubmittedResourceReport _parseResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final code = json['reason'] as String;
      return SubmittedResourceReport(
        id: json['id'] as String,
        resourceId: json['resourceId'] as String,
        reason: ReportReason.values.singleWhere((item) => item.apiCode == code),
        submittedAtUtc: DateTime.parse(json['submittedAtUtc'] as String),
        status: json['status'] as String,
      );
    } catch (_) {
      throw const ReportRepositoryException(
        ReportRepositoryErrorType.invalidResponse,
      );
    }
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
