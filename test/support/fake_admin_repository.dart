import 'package:bridge_pdx/models/admin_models.dart';
import 'package:bridge_pdx/repositories/admin_repository.dart';
import 'package:bridge_pdx/storage/admin_token_store.dart';

class FakeAdminTokenStore implements AdminTokenStore {
  StoredAdminToken? token;
  int writes = 0;
  int clears = 0;

  @override
  Future<void> clear() async {
    clears++;
    token = null;
  }

  @override
  Future<StoredAdminToken?> read() async => token;

  @override
  Future<void> write(StoredAdminToken value) async {
    writes++;
    token = value;
  }
}

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({
    this.validSession = false,
    this.profile = const AdministratorProfile(
      id: 'admin-1',
      email: 'admin@example.invalid',
    ),
    this.onLogin,
    this.onFetchReports,
    this.onFetchReport,
    this.onUpdateStatus,
    this.onGetMe,
  });

  bool validSession;
  AdministratorProfile profile;
  Future<void> Function(String email, String password)? onLogin;
  Future<AdminReportPage> Function(AdminReportFilter filter)? onFetchReports;
  Future<AdminReport> Function(String id)? onFetchReport;
  Future<AdminReport> Function(String id, AdminReportStatus status)?
  onUpdateStatus;
  Future<AdministratorProfile> Function()? onGetMe;
  final List<AdminReportFilter> reportRequests = [];
  final List<AdminReportStatus> statusUpdates = [];
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<void> login({required String email, required String password}) async {
    loginCalls++;
    if (onLogin != null) await onLogin!(email, password);
    validSession = true;
  }

  @override
  Future<bool> hasValidSession() async => validSession;

  @override
  Future<AdministratorProfile> getMe() async =>
      onGetMe == null ? profile : onGetMe!();

  @override
  Future<AdminReportPage> fetchReports(AdminReportFilter filter) async {
    reportRequests.add(filter);
    if (onFetchReports != null) return onFetchReports!(filter);
    return AdminReportPage(
      items: [sampleAdminReport],
      page: filter.page,
      pageSize: filter.pageSize,
      totalCount: 1,
    );
  }

  @override
  Future<AdminReport> fetchReport(String id) async =>
      onFetchReport == null ? sampleAdminReport : onFetchReport!(id);

  @override
  Future<AdminReport> updateStatus(String id, AdminReportStatus status) async {
    statusUpdates.add(status);
    if (onUpdateStatus != null) return onUpdateStatus!(id, status);
    return _copyWithStatus(sampleAdminReport, status);
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    validSession = false;
  }

  @override
  void close() {}
}

final sampleAdminReport = AdminReport(
  id: '10000000-0000-0000-0000-000000000001',
  reason: AdminReportReason.incorrectHours,
  details: 'Hours changed.',
  status: AdminReportStatus.pending,
  submittedAtUtc: DateTime.utc(2026, 10, 8, 12),
  reviewedAtUtc: null,
  reviewingAdministratorId: null,
  resource: const AdminReportResource(
    id: 'food-1',
    name: 'Sample Active Food Desk',
    category: 'Food',
    streetAddress: '101 Sample Street',
    city: 'Portland',
    state: 'OR',
    zipCode: '97201',
  ),
);

AdminReport _copyWithStatus(AdminReport report, AdminReportStatus status) =>
    AdminReport(
      id: report.id,
      reason: report.reason,
      details: report.details,
      status: status,
      submittedAtUtc: report.submittedAtUtc,
      reviewedAtUtc: DateTime.utc(2026, 10, 9),
      reviewingAdministratorId: 'admin-1',
      resource: report.resource,
    );
