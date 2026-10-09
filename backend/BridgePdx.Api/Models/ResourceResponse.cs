namespace BridgePdx.Api.Models;

public sealed record ResourceResponse(
    string Id,
    string Name,
    string Category,
    string Description,
    string StreetAddress,
    string City,
    string State,
    string ZipCode,
    string Phone,
    string Website,
    string Hours,
    string Eligibility,
    IReadOnlyList<string> DocumentsToBring,
    IReadOnlyList<string> ServicesOffered,
    IReadOnlyList<string> LanguagesSupported,
    string AccessibilityInformation,
    bool IsOpenNow,
    bool IsWheelchairAccessible,
    DateOnly LastVerified,
    bool IsActive
);
