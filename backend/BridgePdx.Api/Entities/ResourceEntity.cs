using System.ComponentModel.DataAnnotations;

namespace BridgePdx.Api.Entities;

public sealed class ResourceEntity
{
    [Key, StringLength(50)]
    public required string Id { get; set; }

    [StringLength(150)]
    public required string Name { get; set; }

    [StringLength(50)]
    public required string Category { get; set; }

    [StringLength(4000)]
    public required string Description { get; set; }

    [StringLength(200)]
    public required string StreetAddress { get; set; }

    [StringLength(100)]
    public required string City { get; set; }

    [StringLength(2, MinimumLength = 2)]
    public required string State { get; set; }

    [StringLength(5, MinimumLength = 5), RegularExpression(@"^\d{5}$")]
    public required string ZipCode { get; set; }

    [Phone, StringLength(30)]
    public required string Phone { get; set; }

    [Url, StringLength(500)]
    public required string Website { get; set; }

    [StringLength(500)]
    public required string Hours { get; set; }

    [StringLength(2000)]
    public required string Eligibility { get; set; }

    public required string[] DocumentsToBring { get; set; }
    public required string[] ServicesOffered { get; set; }
    public required string[] LanguagesSupported { get; set; }

    [StringLength(2000)]
    public required string AccessibilityInformation { get; set; }

    public bool IsOpenNow { get; set; }
    public bool IsWheelchairAccessible { get; set; }
    public DateOnly LastVerified { get; set; }
    public bool IsActive { get; set; }
}
