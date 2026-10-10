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
}
