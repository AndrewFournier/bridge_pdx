import 'package:bridge_pdx/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BridgePDX home screen loads with all resource categories', (
    tester,
  ) async {
    await tester.pumpWidget(const BridgePdxApp());

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
    await tester.pumpWidget(const BridgePdxApp());

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
    await tester.pumpWidget(const BridgePdxApp());

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
    await tester.pumpWidget(const BridgePdxApp());
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
    await tester.pump();

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
    await tester.pump();

    expect(find.text('Rose City Community Pantry'), findsOneWidget);
    expect(find.text('Evergreen Wellness Hub'), findsOneWidget);
    expect(find.text('Little Bridges Family Center'), findsNothing);
  });
}

Future<void> _searchForZip(WidgetTester tester, String zipCode) async {
  await tester.pumpWidget(const BridgePdxApp());
  await tester.enterText(find.byKey(const Key('zip-code-field')), zipCode);
  await tester.tap(find.byKey(const Key('zip-search-button')));
  await tester.pumpAndSettle();
}
