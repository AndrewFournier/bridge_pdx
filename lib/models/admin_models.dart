enum AdminReportStatus {
  pending('pending', 'Pending'),
  reviewed('reviewed', 'Reviewed'),
  resolved('resolved', 'Resolved'),
  dismissed('dismissed', 'Dismissed');

  const AdminReportStatus(this.apiCode, this.label);
  final String apiCode;
  final String label;

  static AdminReportStatus fromApi(String value) =>
      values.singleWhere((status) => status.apiCode == value);

  List<AdminReportStatus> get allowedTransitions => switch (this) {
    pending => const [reviewed, dismissed],
    reviewed => const [resolved, dismissed],
    resolved || dismissed => const [],
  };
}

enum AdminReportReason {
  incorrectHours('incorrect_hours', 'Incorrect hours'),
  incorrectAddress('incorrect_address', 'Incorrect address'),
  incorrectPhoneOrWebsite(
    'incorrect_phone_or_website',
    'Incorrect phone or website',
  ),
  serviceNoLongerAvailable(
    'service_no_longer_available',
    'Service no longer available',
  ),
  eligibilityIncorrect('eligibility_incorrect', 'Eligibility incorrect'),
  accessibilityIncorrect('accessibility_incorrect', 'Accessibility incorrect'),
  other('other', 'Other');

  const AdminReportReason(this.apiCode, this.label);
  final String apiCode;
  final String label;

  static AdminReportReason fromApi(String value) =>
      values.singleWhere((reason) => reason.apiCode == value);
}

class AdministratorProfile {
  const AdministratorProfile({required this.id, required this.email});
  final String id;
  final String email;

  factory AdministratorProfile.fromJson(Map<String, dynamic> json) =>
      AdministratorProfile(
        id: json['id'] as String,
        email: json['email'] as String,
      );
}

class AdminReportResource {
  const AdminReportResource({
    required this.id,
    required this.name,
    required this.category,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  final String id;
  final String name;
  final String category;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;

  String get fullAddress => '$streetAddress, $city, $state $zipCode';

  factory AdminReportResource.fromJson(Map<String, dynamic> json) =>
      AdminReportResource(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        streetAddress: json['streetAddress'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        zipCode: json['zipCode'] as String,
      );
}

class AdminReport {
  const AdminReport({
    required this.id,
    required this.reason,
    required this.details,
    required this.status,
    required this.submittedAtUtc,
    required this.reviewedAtUtc,
    required this.reviewingAdministratorId,
    required this.resource,
  });

  final String id;
  final AdminReportReason reason;
  final String? details;
  final AdminReportStatus status;
  final DateTime submittedAtUtc;
  final DateTime? reviewedAtUtc;
  final String? reviewingAdministratorId;
  final AdminReportResource resource;

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
    id: json['id'] as String,
    reason: AdminReportReason.fromApi(json['reason'] as String),
    details: json['details'] as String?,
    status: AdminReportStatus.fromApi(json['status'] as String),
    submittedAtUtc: DateTime.parse(json['submittedAtUtc'] as String),
    reviewedAtUtc: json['reviewedAtUtc'] == null
        ? null
        : DateTime.parse(json['reviewedAtUtc'] as String),
    reviewingAdministratorId: json['reviewingAdministratorId'] as String?,
    resource: AdminReportResource.fromJson(
      json['resource'] as Map<String, dynamic>,
    ),
  );
}

class AdminReportPage {
  const AdminReportPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });
  final List<AdminReport> items;
  final int page;
  final int pageSize;
  final int totalCount;

  bool get hasNextPage => page * pageSize < totalCount;
}

class AdminReportFilter {
  const AdminReportFilter({
    this.page = 1,
    this.pageSize = 25,
    this.status,
    this.reason,
    this.resourceId,
    this.submittedFromUtc,
    this.submittedToUtc,
  });

  final int page;
  final int pageSize;
  final AdminReportStatus? status;
  final AdminReportReason? reason;
  final String? resourceId;
  final DateTime? submittedFromUtc;
  final DateTime? submittedToUtc;

  AdminReportFilter copyWith({
    int? page,
    int? pageSize,
    AdminReportStatus? status,
    AdminReportReason? reason,
    String? resourceId,
    DateTime? submittedFromUtc,
    DateTime? submittedToUtc,
    bool clearStatus = false,
    bool clearReason = false,
    bool clearResourceId = false,
    bool clearSubmittedFrom = false,
    bool clearSubmittedTo = false,
  }) => AdminReportFilter(
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
    status: clearStatus ? null : status ?? this.status,
    reason: clearReason ? null : reason ?? this.reason,
    resourceId: clearResourceId ? null : resourceId ?? this.resourceId,
    submittedFromUtc: clearSubmittedFrom
        ? null
        : submittedFromUtc ?? this.submittedFromUtc,
    submittedToUtc: clearSubmittedTo
        ? null
        : submittedToUtc ?? this.submittedToUtc,
  );
}
