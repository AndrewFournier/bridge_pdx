import 'dart:async';

import 'package:bridge_pdx/app.dart';
import 'package:bridge_pdx/models/admin_models.dart';
import 'package:bridge_pdx/repositories/admin_repository.dart';
import 'package:bridge_pdx/screens/admin/administrator_report_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_admin_repository.dart';
import 'support/fake_report_repository.dart';
import 'support/fake_resource_repository.dart';

void main() {
  testWidgets('successful login opens report dashboard', (tester) async {
    final repository = FakeAdminRepository();
    await _pumpAdminApp(tester, repository);

    await tester.enterText(
      find.byKey(const Key('admin-email-field')),
      'admin@example.invalid',
    );
    await tester.enterText(
      find.byKey(const Key('admin-password-field')),
      'test-password',
    );
    await tester.tap(find.byKey(const Key('admin-login-button')));
    await tester.pumpAndSettle();

    expect(find.text('Report review'), findsOneWidget);
    expect(find.text('Sample Active Food Desk'), findsOneWidget);
    expect(repository.loginCalls, 1);
  });

  testWidgets('failed login shows generic error and retains form', (
    tester,
  ) async {
    final repository = FakeAdminRepository(
      onLogin: (_, _) async => throw const AdminRepositoryException(
        AdminRepositoryErrorType.invalidCredentials,
      ),
    );
    await _pumpAdminApp(tester, repository);
    await tester.enterText(
      find.byKey(const Key('admin-email-field')),
      'unknown@example.invalid',
    );
    await tester.enterText(
      find.byKey(const Key('admin-password-field')),
      'wrong',
    );
    await tester.tap(find.byKey(const Key('admin-login-button')));
    await tester.pump();

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(find.text('unknown@example.invalid'), findsOneWidget);
  });

  testWidgets('login prevents duplicate submissions', (tester) async {
    final pending = Completer<void>();
    final repository = FakeAdminRepository(onLogin: (_, _) => pending.future);
    await _pumpAdminApp(tester, repository);
    await tester.enterText(
      find.byKey(const Key('admin-email-field')),
      'admin@example.invalid',
    );
    await tester.enterText(
      find.byKey(const Key('admin-password-field')),
      'test-password',
    );
    await tester.tap(find.byKey(const Key('admin-login-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-login-button')));

    expect(repository.loginCalls, 1);
    expect(find.byKey(const Key('admin-login-progress')), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard shows loading then empty state', (tester) async {
    final pending = Completer<AdminReportPage>();
    final repository = FakeAdminRepository(
      validSession: true,
      onFetchReports: (_) => pending.future,
    );
    await _pumpAdminApp(tester, repository);
    expect(find.byKey(const Key('admin-reports-loading')), findsOneWidget);

    pending.complete(
      const AdminReportPage(items: [], page: 1, pageSize: 25, totalCount: 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('No reports match these filters.'), findsOneWidget);
  });

  testWidgets('dashboard retries after a loading failure', (tester) async {
    var attempts = 0;
    final repository = FakeAdminRepository(
      validSession: true,
      onFetchReports: (filter) async {
        attempts++;
        if (attempts == 1) {
          throw const AdminRepositoryException(
            AdminRepositoryErrorType.connection,
          );
        }
        return AdminReportPage(
          items: [sampleAdminReport],
          page: 1,
          pageSize: filter.pageSize,
          totalCount: 1,
        );
      },
    );
    await _pumpAdminApp(tester, repository);
    expect(find.text('Unable to load reports.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-reports-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Sample Active Food Desk'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('valid transition updates report status', (tester) async {
    final repository = FakeAdminRepository(validSession: true);
    await tester.pumpWidget(
      MaterialApp(
        home: AdministratorReportDetailScreen(
          repository: repository,
          reportId: sampleAdminReport.id,
          onUnauthorized: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-status-reviewed')), findsOneWidget);
    expect(find.byKey(const Key('admin-status-dismissed')), findsOneWidget);
    expect(find.byKey(const Key('admin-status-resolved')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('admin-status-reviewed')));
    await tester.tap(find.byKey(const Key('admin-status-reviewed')));
    await tester.pumpAndSettle();
    expect(repository.statusUpdates, [AdminReportStatus.reviewed]);
    expect(find.text('Reviewed'), findsWidgets);
    expect(find.byKey(const Key('admin-status-resolved')), findsOneWidget);
  });

  testWidgets('rejected status update displays validation feedback', (
    tester,
  ) async {
    final repository = FakeAdminRepository(
      validSession: true,
      onUpdateStatus: (_, _) async => throw const AdminRepositoryException(
        AdminRepositoryErrorType.validation,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AdministratorReportDetailScreen(
          repository: repository,
          reportId: sampleAdminReport.id,
          onUnauthorized: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('admin-status-reviewed')));
    await tester.tap(find.byKey(const Key('admin-status-reviewed')));
    await tester.pump();
    expect(find.text('That status transition is not allowed.'), findsOneWidget);
  });

  testWidgets('logout clears session and returns to login', (tester) async {
    final repository = FakeAdminRepository(validSession: true);
    await _pumpAdminApp(tester, repository);
    await tester.tap(find.byKey(const Key('admin-logout-button')));
    await tester.pumpAndSettle();

    expect(repository.logoutCalls, 1);
    expect(find.text('Administrator sign in'), findsOneWidget);
  });
}

Future<void> _pumpAdminApp(
  WidgetTester tester,
  FakeAdminRepository repository,
) async {
  await tester.pumpWidget(
    BridgePdxApp(
      repository: FakeResourceRepository(),
      reportRepository: FakeReportRepository(),
      adminRepository: repository,
      initialRoute: '/admin',
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
