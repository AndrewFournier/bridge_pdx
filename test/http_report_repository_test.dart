import 'dart:convert';

import 'package:bridge_pdx/models/outdated_information_report.dart';
import 'package:bridge_pdx/repositories/http_report_repository.dart';
import 'package:bridge_pdx/repositories/report_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'maps reason to stable API code and parses successful response',
    () async {
      late Map<String, dynamic> body;
      final repository = HttpReportRepository(
        baseUri: Uri.parse('http://localhost:5080'),
        client: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 'report-1',
              'resourceId': 'food-1',
              'reason': 'incorrect_hours',
              'details': 'Changed hours',
              'submittedAtUtc': '2026-10-09T12:00:00Z',
              'status': 'pending',
            }),
            201,
          );
        }),
      );

      final result = await repository.submitReport(
        const OutdatedInformationReport(
          resourceId: 'food-1',
          reason: ReportReason.incorrectHours,
          details: 'Changed hours',
        ),
      );

      expect(body['reason'], 'incorrect_hours');
      expect(result.reason, ReportReason.incorrectHours);
      expect(result.status, 'pending');
    },
  );

  for (final entry in {
    400: ReportRepositoryErrorType.validation,
    404: ReportRepositoryErrorType.notFound,
    429: ReportRepositoryErrorType.rateLimited,
    500: ReportRepositoryErrorType.server,
  }.entries) {
    test('maps ${entry.key} to ${entry.value.name}', () async {
      final repository = HttpReportRepository(
        baseUri: Uri.parse('http://localhost:5080'),
        client: MockClient((_) async => http.Response('', entry.key)),
      );
      await expectLater(
        repository.submitReport(
          const OutdatedInformationReport(
            resourceId: 'food-1',
            reason: ReportReason.other,
            details: null,
          ),
        ),
        throwsA(
          isA<ReportRepositoryException>().having(
            (error) => error.type,
            'type',
            entry.value,
          ),
        ),
      );
    });
  }
}
