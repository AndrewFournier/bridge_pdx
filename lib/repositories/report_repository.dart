import '../models/outdated_information_report.dart';

enum ReportRepositoryErrorType {
  validation,
  notFound,
  rateLimited,
  connection,
  server,
  invalidResponse,
}

class ReportRepositoryException implements Exception {
  const ReportRepositoryException(this.type);
  final ReportRepositoryErrorType type;
}

abstract interface class ReportRepository {
  Future<SubmittedResourceReport> submitReport(
    OutdatedInformationReport report,
  );

  void close();
}
