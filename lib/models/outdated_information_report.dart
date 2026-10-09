enum ReportReason {
  incorrectHours('Incorrect hours'),
  incorrectAddress('Incorrect address'),
  incorrectContact('Incorrect phone or website'),
  serviceUnavailable('Service no longer available'),
  incorrectEligibility('Eligibility information is incorrect'),
  incorrectAccessibility('Accessibility information is incorrect'),
  other('Other');

  const ReportReason(this.label);

  final String label;
}

class OutdatedInformationReport {
  const OutdatedInformationReport({
    required this.resourceId,
    required this.reason,
    required this.details,
  });

  final String resourceId;
  final ReportReason reason;
  final String details;
}
