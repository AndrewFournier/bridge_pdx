import '../models/admin_models.dart';

enum AdminRepositoryErrorType {
  invalidCredentials,
  unauthorized,
  validation,
  notFound,
  rateLimited,
  connection,
  server,
  invalidResponse,
}

class AdminRepositoryException implements Exception {
  const AdminRepositoryException(this.type);
  final AdminRepositoryErrorType type;
}

abstract interface class AdminRepository {
  Future<void> login({required String email, required String password});
  Future<bool> hasValidSession();
  Future<AdministratorProfile> getMe();
  Future<AdminReportPage> fetchReports(AdminReportFilter filter);
  Future<AdminReport> fetchReport(String id);
  Future<AdminReport> updateStatus(String id, AdminReportStatus status);
  Future<void> logout();
  void close();
}
