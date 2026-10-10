import 'dart:async';

import 'package:bridge_pdx/app.dart';
import 'package:bridge_pdx/data/sample_resources.dart';
import 'package:bridge_pdx/models/community_resource.dart';
import 'package:bridge_pdx/repositories/resource_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_resource_repository.dart';

void main() {
  testWidgets('resource list displays loading then successful API results', (
    tester,
  ) async {
    final pending = Completer<List<CommunityResource>>();
    final repository = FakeResourceRepository(
      onFetchResources: (_, _, _) => pending.future,
    );
    await _openFood(tester, repository);

    expect(find.byKey(const Key('resource-list-loading')), findsOneWidget);

    pending.complete([sampleResources.first]);
    await tester.pumpAndSettle();

    expect(find.text('Rose City Community Pantry'), findsOneWidget);
  });

  testWidgets('resource list displays the existing empty state', (
    tester,
  ) async {
    final repository = FakeResourceRepository(
      onFetchResources: (_, _, _) async => [],
    );
    await _openFood(tester, repository);

    expect(find.text('No sample resources found'), findsOneWidget);
  });

  testWidgets('connection error shows a friendly retry state', (tester) async {
    final repository = FakeResourceRepository(
      onFetchResources: (_, _, _) => Future.error(
        const ResourceRepositoryException(
          ResourceRepositoryErrorType.connection,
        ),
      ),
    );
    await _openFood(tester, repository);

    expect(find.text('Unable to connect to BridgePDX'), findsOneWidget);
    expect(find.byKey(const Key('resource-list-retry')), findsOneWidget);
  });

  testWidgets('retry recovers after an initial connection failure', (
    tester,
  ) async {
    var attempts = 0;
    final repository = FakeResourceRepository(
      onFetchResources: (_, _, _) {
        attempts++;
        if (attempts == 1) {
          throw const ResourceRepositoryException(
            ResourceRepositoryErrorType.connection,
          );
        }
        return Future.value([sampleResources.first]);
      },
    );
    await _openFood(tester, repository);

    await tester.tap(find.byKey(const Key('resource-list-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Rose City Community Pantry'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('resource details display a loading state', (tester) async {
    final pending = Completer<CommunityResource>();
    final repository = FakeResourceRepository(
      onFetchResource: (_) => pending.future,
    );
    await _openFood(tester, repository);

    await tester.tap(find.byKey(const Key('resource-card-food-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('resource-detail-loading')), findsOneWidget);

    pending.complete(sampleResources.first);
    await tester.pumpAndSettle();
  });

  testWidgets('resource detail 404 displays a not-found state', (tester) async {
    final repository = FakeResourceRepository(
      onFetchResource: (_) => Future.error(
        const ResourceRepositoryException(ResourceRepositoryErrorType.notFound),
      ),
    );
    await _openFood(tester, repository);

    await tester.tap(find.byKey(const Key('resource-card-food-1')));
    await tester.pumpAndSettle();

    expect(find.text('Resource not found'), findsOneWidget);
    expect(find.byKey(const Key('resource-detail-not-found')), findsOneWidget);
  });

  testWidgets('an older response cannot replace newer filtered results', (
    tester,
  ) async {
    final requests = <Completer<List<CommunityResource>>>[];
    final repository = FakeResourceRepository(
      onFetchResources: (_, _, _) {
        final request = Completer<List<CommunityResource>>();
        requests.add(request);
        return request.future;
      },
    );
    await _openFood(tester, repository);

    await tester.tap(find.byKey(const Key('filter-open-now')));
    await tester.pump();
    expect(requests, hasLength(2));

    requests[1].complete([sampleResources[1]]);
    await tester.pumpAndSettle();
    expect(find.text('Willamette Meal Share'), findsOneWidget);

    requests[0].complete([sampleResources.first]);
    await tester.pump();
    expect(find.text('Willamette Meal Share'), findsOneWidget);
    expect(find.text('Rose City Community Pantry'), findsNothing);
  });
}

Future<void> _openFood(
  WidgetTester tester,
  FakeResourceRepository repository,
) async {
  await tester.pumpWidget(BridgePdxApp(repository: repository));
  await tester.tap(find.byKey(const Key('category-food')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
