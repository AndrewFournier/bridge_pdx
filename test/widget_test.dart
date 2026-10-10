import 'package:bridge_pdx/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_resource_repository.dart';
import 'support/fake_report_repository.dart';

void main() {
  testWidgets('BridgePDX home screen loads with all resource categories', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('BridgePDX'), findsOneWidget);
    expect(find.text('Find help near you'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Housing'), findsOneWidget);
    expect(find.text('Healthcare'), findsOneWidget);
    expect(find.text('Family Support'), findsOneWidget);
    expect(find.text('Employment'), findsOneWidget);
    expect(find.text('Transportation'), findsOneWidget);
  });

  testWidgets('Food category opens a filtered Food Resources screen', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('category-food')));
    await tester.pumpAndSettle();

    expect(find.text('Food Resources'), findsOneWidget);
    expect(find.textContaining('Sample data'), findsOneWidget);
    expect(find.text('Rose City Community Pantry'), findsOneWidget);
    expect(find.text('Willamette Meal Share'), findsOneWidget);
    expect(find.text('Bridgeway Housing Desk'), findsNothing);
    expect(find.text('Harbor Community Clinic'), findsNothing);
  });

  testWidgets('invalid ZIP code displays inline error and does not navigate', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.enterText(find.byKey(const Key('zip-code-field')), '9720A');
    await tester.tap(find.byKey(const Key('zip-search-button')));
    await tester.pump();

    expect(find.text('Enter a five-digit ZIP code.'), findsOneWidget);
    expect(find.text('Resources for 9720A'), findsNothing);
  });

  testWidgets('valid ZIP search shows only resources in that ZIP', (
    tester,
  ) async {
    await _searchForZip(tester, ' 97201 ');

    expect(find.text('Resources for 97201'), findsOneWidget);
    expect(find.text('Rose City Community Pantry'), findsOneWidget);
    expect(find.text('Harbor Community Clinic'), findsNothing);
    expect(find.text('Willamette Meal Share'), findsNothing);
  });

  testWidgets('category browsing combines category and ZIP filters', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.enterText(find.byKey(const Key('zip-code-field')), '97201');

    await tester.tap(find.byKey(const Key('category-food')));
    await tester.pumpAndSettle();

    expect(find.text('Food in 97201'), findsOneWidget);
    expect(find.text('Rose City Community Pantry'), findsOneWidget);
    expect(find.text('Willamette Meal Share'), findsNothing);
    expect(find.text('Evergreen Wellness Hub'), findsNothing);
  });

  testWidgets('Open now filter immediately removes closed resources', (
    tester,
  ) async {
    await _searchForZip(tester, '97201');

    expect(find.text('Evergreen Wellness Hub'), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-open-now')));
    await tester.pumpAndSettle();

    expect(find.text('Rose City Community Pantry'), findsOneWidget);
    expect(find.text('Little Bridges Family Center'), findsOneWidget);
    expect(find.text('Evergreen Wellness Hub'), findsNothing);
    expect(find.byKey(const Key('clear-filters-button')), findsOneWidget);
  });

  testWidgets('wheelchair filter shows only accessible resources', (
    tester,
  ) async {
    await _searchForZip(tester, '97201');

    await tester.tap(find.byKey(const Key('filter-wheelchair-accessible')));
    await tester.pumpAndSettle();

    expect(find.text('Rose City Community Pantry'), findsOneWidget);
    expect(find.text('Evergreen Wellness Hub'), findsOneWidget);
    expect(find.text('Little Bridges Family Center'), findsNothing);
  });

  testWidgets('resource card opens the correct complete detail screen', (
    tester,
  ) async {
    await _openFirstFoodResource(tester);

    expect(find.text('Resource details'), findsOneWidget);
    expect(find.text('Rose City Community Pantry'), findsOneWidget);
    expect(
      find.textContaining('Sample data — not a real service listing'),
      findsOneWidget,
    );
    expect(find.text('Services offered'), findsOneWidget);
    expect(find.text('Eligibility requirements'), findsOneWidget);
    expect(find.text('Documents to bring'), findsOneWidget);
    expect(find.text('Languages supported'), findsOneWidget);
    expect(find.text('Accessibility'), findsOneWidget);
  });

  testWidgets('report action opens anonymous report form', (tester) async {
    await _openReportForm(tester);

    expect(find.text('Report outdated information'), findsOneWidget);
    expect(find.textContaining('submitted anonymously'), findsOneWidget);
    expect(find.text('Incorrect hours'), findsOneWidget);
    expect(find.byKey(const Key('report-details-field')), findsOneWidget);
  });

  testWidgets('report submission requires a selected reason', (tester) async {
    await _openReportForm(tester);

    await tester.ensureVisible(find.byKey(const Key('submit-report-button')));
    await tester.tap(find.byKey(const Key('submit-report-button')));
    await tester.pump();

    expect(find.text('Select a reason before submitting.'), findsOneWidget);
    expect(find.text('Report outdated information'), findsOneWidget);
  });

  testWidgets('valid report confirms and returns to resource details', (
    tester,
  ) async {
    await _openReportForm(tester);

    await tester.tap(find.byKey(const Key('report-reason-incorrectHours')));
    await tester.ensureVisible(find.byKey(const Key('submit-report-button')));
    await tester.tap(find.byKey(const Key('submit-report-button')));
    await tester.pumpAndSettle();

    expect(find.text('Resource details'), findsOneWidget);
    expect(find.byKey(const Key('report-confirmation')), findsOneWidget);
    expect(find.textContaining('submitted for review'), findsOneWidget);
  });
}

Future<void> _searchForZip(WidgetTester tester, String zipCode) async {
  await _pumpApp(tester);
  await tester.enterText(find.byKey(const Key('zip-code-field')), zipCode);
  await tester.tap(find.byKey(const Key('zip-search-button')));
  await tester.pumpAndSettle();
}

Future<void> _openFirstFoodResource(WidgetTester tester) async {
  await _pumpApp(tester);
  await tester.tap(find.byKey(const Key('category-food')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('resource-card-food-1')));
  await tester.pumpAndSettle();
}

Future<void> _pumpApp(
  WidgetTester tester, [
  FakeResourceRepository? repository,
]) async {
  await tester.pumpWidget(
    BridgePdxApp(
      repository: repository ?? FakeResourceRepository(),
      reportRepository: FakeReportRepository(),
    ),
  );
}

Future<void> _openReportForm(WidgetTester tester) async {
  await _openFirstFoodResource(tester);
  await tester.ensureVisible(
    find.byKey(const Key('report-outdated-information-button')),
  );
  await tester.tap(find.byKey(const Key('report-outdated-information-button')));
  await tester.pumpAndSettle();
}
