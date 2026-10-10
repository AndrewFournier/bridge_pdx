import 'package:bridge_pdx/models/outdated_information_report.dart';
import 'package:bridge_pdx/repositories/report_repository.dart';

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({this.onSubmit});

  final Future<SubmittedResourceReport> Function(
    OutdatedInformationReport report,
  )?
  onSubmit;
  final List<OutdatedInformationReport> submittedReports = [];

  @override
  Future<SubmittedResourceReport> submitReport(
    OutdatedInformationReport report,
  ) async {
    submittedReports.add(report);
    if (onSubmit != null) return onSubmit!(report);
    return SubmittedResourceReport(
      id: 'sample-report-id',
      resourceId: report.resourceId,
      reason: report.reason,
      submittedAtUtc: DateTime.utc(2026, 10, 9),
      status: 'pending',
    );
  }

  @override
  void close() {}
}
