using System.ComponentModel.DataAnnotations;

namespace BridgePdx.Api.Models;

public sealed class ResourceQueryParameters
{
    [RegularExpression(
        @"^[A-Za-z][A-Za-z -]{0,49}$",
        ErrorMessage = "Category contains unsupported characters."
    )]
    public string? Category { get; init; }

    [RegularExpression(@"^\d{5}$", ErrorMessage = "ZIP code must contain five digits.")]
    public string? ZipCode { get; init; }

    public bool? OpenNow { get; init; }
    public bool? WheelchairAccessible { get; init; }
}
