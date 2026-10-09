using BridgePdx.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace BridgePdx.Api.Data;

public static class DevelopmentDataSeeder
{
    public static async Task SeedAsync(BridgePdxDbContext dbContext)
    {
        if (await dbContext.Resources.AnyAsync())
        {
            return;
        }

        dbContext.Resources.AddRange(
            CreateResource(
                "sample-food-97201",
                "Sample Rose Bridge Pantry",
                "Food",
                "101 Fictional Way",
                "Portland",
                "97201",
                true,
                true
            ),
            CreateResource(
                "sample-housing-97005",
                "Example Harbor Housing Desk",
                "Housing",
                "202 Demonstration Avenue",
                "Beaverton",
                "97005",
                false,
                true
            ),
            CreateResource(
                "sample-health-97030",
                "Sample Evergreen Wellness Room",
                "Healthcare",
                "303 Placeholder Street",
                "Gresham",
                "97030",
                true,
                false
            )
        );

        await dbContext.SaveChangesAsync();
    }

    private static ResourceEntity CreateResource(
        string id,
        string name,
        string category,
        string streetAddress,
        string city,
        string zipCode,
        bool isOpenNow,
        bool isWheelchairAccessible
    ) => new()
    {
        Id = id,
        Name = name,
        Category = category,
        Description =
            "A clearly fictional development listing used to exercise the BridgePDX API.",
        StreetAddress = streetAddress,
        City = city,
        State = "OR",
        ZipCode = zipCode,
        Phone = "(503) 555-0100",
        Website = $"https://{id}.example.org",
        Hours = "Sample hours: Monday–Friday, 9 AM–5 PM",
        Eligibility = "Fictional eligibility screening applies.",
        DocumentsToBring = ["Sample photo identification if available"],
        ServicesOffered = [$"Sample {category.ToLowerInvariant()} navigation"],
        LanguagesSupported = ["English", "Spanish by sample appointment"],
        AccessibilityInformation = isWheelchairAccessible
            ? "Fictional step-free entrance and accessible restroom."
            : "Fictional site has steps; call the sample number for alternatives.",
        IsOpenNow = isOpenNow,
        IsWheelchairAccessible = isWheelchairAccessible,
        LastVerified = new DateOnly(2026, 9, 15),
        IsActive = true,
    };
}
