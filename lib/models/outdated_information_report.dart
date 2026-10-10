enum ReportReason {
  incorrectHours('Incorrect hours', 'incorrect_hours'),
  incorrectAddress('Incorrect address', 'incorrect_address'),
  incorrectContact('Incorrect phone or website', 'incorrect_phone_or_website'),
  serviceUnavailable(
    'Service no longer available',
    'service_no_longer_available',
  ),
  incorrectEligibility(
    'Eligibility information is incorrect',
    'eligibility_incorrect',
  ),
  incorrectAccessibility(
    'Accessibility information is incorrect',
    'accessibility_incorrect',
  ),
  other('Other', 'other');

  const ReportReason(this.label, this.apiCode);

  final String label;
  final String apiCode;
}

class OutdatedInformationReport {
  const OutdatedInformationReport({
    required this.resourceId,
    required this.reason,
    required this.details,
  });

  final String resourceId;
  final ReportReason reason;
  final String? details;
}

class SubmittedResourceReport {
  const SubmittedResourceReport({
    required this.id,
    required this.resourceId,
    required this.reason,
    required this.submittedAtUtc,
    required this.status,
  });

  final String id;
  final String resourceId;
  final ReportReason reason;
  final DateTime submittedAtUtc;
  final String status;
}
