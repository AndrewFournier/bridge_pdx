import 'dart:async';

import 'package:bridge_pdx/data/sample_resources.dart';
import 'package:bridge_pdx/models/outdated_information_report.dart';
import 'package:bridge_pdx/repositories/report_repository.dart';
import 'package:bridge_pdx/screens/report_outdated_information_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_report_repository.dart';

void main() {
  test('every report reason has the expected stable API code', () {
    expect(ReportReason.values.map((reason) => reason.apiCode), {
      'incorrect_hours',
      'incorrect_address',
      'incorrect_phone_or_website',
      'service_no_longer_available',
      'eligibility_incorrect',
      'accessibility_incorrect',
      'other',
    });
  });

  testWidgets('shows a remaining-character count', (tester) async {
    await _pumpForm(tester, FakeReportRepository());
    expect(find.text('500 characters remaining'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('report-details-field')),
      'abc',
    );
    await tester.pump();
    expect(find.text('497 characters remaining'), findsOneWidget);
  });

  testWidgets('disables submission and prevents duplicate requests', (
    tester,
  ) async {
    final completer = Completer<SubmittedResourceReport>();
    final repository = FakeReportRepository(onSubmit: (_) => completer.future);
    await _pumpForm(tester, repository);
    await tester.tap(find.byKey(const Key('report-reason-other')));
    await tester.ensureVisible(find.byKey(const Key('submit-report-button')));
    await tester.tap(find.byKey(const Key('submit-report-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-report-button')));
    expect(repository.submittedReports, hasLength(1));
    expect(
      find.byKey(const Key('report-submitting-indicator')),
      findsOneWidget,
    );
    completer.complete(_submitted());
    await tester.pumpAndSettle();
  });

  testWidgets('retains input after failure and allows retry', (tester) async {
    var attempt = 0;
    final repository = FakeReportRepository(
      onSubmit: (report) async {
        attempt++;
        if (attempt == 1) {
          throw const ReportRepositoryException(
            ReportRepositoryErrorType.connection,
          );
        }
        return _submitted();
      },
    );
    await _pumpForm(tester, repository);
    await tester.tap(find.byKey(const Key('report-reason-other')));
    await tester.enterText(
      find.byKey(const Key('report-details-field')),
      'Keep these details',
    );
    await tester.ensureVisible(find.byKey(const Key('submit-report-button')));
    await tester.tap(find.byKey(const Key('submit-report-button')));
    await tester.pump();
    expect(find.textContaining('Check your connection'), findsOneWidget);
    expect(find.text('Keep these details'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('report-reason-other')))
          .selected,
      isTrue,
    );
    await tester.ensureVisible(find.byKey(const Key('submit-report-button')));
    await tester.tap(find.byKey(const Key('submit-report-button')));
    await tester.pumpAndSettle();
    expect(repository.submittedReports, hasLength(2));
  });

  for (final scenario in {
    ReportRepositoryErrorType.notFound: 'no longer available',
    ReportRepositoryErrorType.rateLimited: 'Too many reports',
  }.entries) {
    testWidgets('shows friendly ${scenario.key.name} feedback', (tester) async {
      final repository = FakeReportRepository(
        onSubmit: (_) async => throw ReportRepositoryException(scenario.key),
      );
      await _pumpForm(tester, repository);
      await tester.tap(find.byKey(const Key('report-reason-other')));
      await tester.ensureVisible(find.byKey(const Key('submit-report-button')));
      await tester.tap(find.byKey(const Key('submit-report-button')));
      await tester.pump();
      final error = tester.widget<Text>(
        find.byKey(const Key('report-submission-error')),
      );
      expect(error.data, contains(scenario.value));
    });
  }
}

Future<void> _pumpForm(WidgetTester tester, FakeReportRepository repository) =>
    tester.pumpWidget(
      MaterialApp(
        home: ReportOutdatedInformationScreen(
          resource: sampleResources.first,
          repository: repository,
        ),
      ),
    );

SubmittedResourceReport _submitted() => SubmittedResourceReport(
  id: 'report-1',
  resourceId: sampleResources.first.id,
  reason: ReportReason.other,
  submittedAtUtc: DateTime.utc(2026, 10, 9),
  status: 'pending',
);
