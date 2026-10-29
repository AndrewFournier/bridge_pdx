using System.ComponentModel.DataAnnotations;

namespace BridgePdx.Api.Models;

public sealed class AdminReportQueryParameters : IValidatableObject
{
    [Range(1, int.MaxValue)]
    public int Page { get; init; } = 1;

    [Range(1, 100)]
    public int PageSize { get; init; } = 25;

    public string? Status { get; init; }
    public string? Reason { get; init; }

    [StringLength(50)]
    public string? ResourceId { get; init; }

    public DateTimeOffset? SubmittedFromUtc { get; init; }
    public DateTimeOffset? SubmittedToUtc { get; init; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (SubmittedFromUtc > SubmittedToUtc)
        {
            yield return new ValidationResult(
                "SubmittedFromUtc must be before or equal to SubmittedToUtc.",
                [nameof(SubmittedFromUtc), nameof(SubmittedToUtc)]
            );
        }
    }
}

public sealed class UpdateReportStatusRequest
{
    [Required]
    public string? Status { get; init; }
}

public sealed record AdminReportResourceResponse(
    string Id,
    string Name,
    string Category,
    string StreetAddress,
    string City,
    string State,
    string ZipCode
);

public sealed record AdminReportResponse(
    Guid Id,
    string Reason,
    string? Details,
    string Status,
    DateTimeOffset SubmittedAtUtc,
    DateTimeOffset? ReviewedAtUtc,
    string? ReviewingAdministratorId,
    AdminReportResourceResponse Resource
);

public sealed record PagedAdminReportsResponse(
    IReadOnlyList<AdminReportResponse> Items,
    int Page,
    int PageSize,
    int TotalCount
);
