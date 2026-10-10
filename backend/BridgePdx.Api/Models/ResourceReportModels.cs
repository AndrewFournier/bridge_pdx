using System.ComponentModel.DataAnnotations;
using BridgePdx.Api.Entities;

namespace BridgePdx.Api.Models;

public sealed class CreateResourceReportRequest
{
    [Required]
    public string? Reason { get; init; }

    [StringLength(500)]
    public string? Details { get; init; }
}

public sealed record ResourceReportResponse(
    Guid Id,
    string ResourceId,
    string Reason,
    string? Details,
    DateTimeOffset SubmittedAtUtc,
    string Status
);

public static class ReportReasonCodes
{
    private static readonly IReadOnlyDictionary<string, ReportReason> Values =
        new Dictionary<string, ReportReason>(StringComparer.Ordinal)
        {
            ["incorrect_hours"] = ReportReason.IncorrectHours,
            ["incorrect_address"] = ReportReason.IncorrectAddress,
            ["incorrect_phone_or_website"] = ReportReason.IncorrectPhoneOrWebsite,
            ["service_no_longer_available"] = ReportReason.ServiceNoLongerAvailable,
            ["eligibility_incorrect"] = ReportReason.EligibilityIncorrect,
            ["accessibility_incorrect"] = ReportReason.AccessibilityIncorrect,
            ["other"] = ReportReason.Other,
        };

    public static bool TryParse(string? code, out ReportReason reason) =>
        Values.TryGetValue(code ?? string.Empty, out reason);

    public static string ToCode(this ReportReason reason) =>
        Values.Single(pair => pair.Value == reason).Key;
}
