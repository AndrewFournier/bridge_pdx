using System.ComponentModel.DataAnnotations;

namespace BridgePdx.Api.Entities;

public enum ReportReason
{
    IncorrectHours,
    IncorrectAddress,
    IncorrectPhoneOrWebsite,
    ServiceNoLongerAvailable,
    EligibilityIncorrect,
    AccessibilityIncorrect,
    Other,
}

public enum ReportReviewStatus
{
    Pending,
    Reviewed,
    Resolved,
    Dismissed,
}

public sealed class ResourceReportEntity
{
    public Guid Id { get; set; }

    [StringLength(50)]
    public required string ResourceId { get; set; }

    public required ResourceEntity Resource { get; set; }
    public ReportReason Reason { get; set; }

    [StringLength(500)]
    public string? Details { get; set; }

    public DateTimeOffset SubmittedAtUtc { get; set; }
    public ReportReviewStatus Status { get; set; }
    public DateTimeOffset? ReviewedAtUtc { get; set; }

    [StringLength(450)]
    public string? ReviewingAdministratorId { get; set; }

    public AdministratorUser? ReviewingAdministrator { get; set; }
}
