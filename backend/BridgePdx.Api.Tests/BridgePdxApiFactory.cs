using BridgePdx.Api.Data;
using BridgePdx.Api.Entities;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;

namespace BridgePdx.Api.Tests;

public sealed class BridgePdxApiFactory : WebApplicationFactory<Program>
{
    private readonly string _databaseName = $"bridgepdx-tests-{Guid.NewGuid()}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureAppConfiguration((_, configuration) =>
        {
            configuration.AddInMemoryCollection(
                new Dictionary<string, string?>
                {
                    ["ConnectionStrings:BridgePdx"] = "Host=unused-for-tests",
                }
            );
        });
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<DbContextOptions<BridgePdxDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<BridgePdxDbContext>>();
            services.AddDbContext<BridgePdxDbContext>(options =>
                options.UseInMemoryDatabase(_databaseName)
            );
        });
    }

    protected override IHost CreateHost(IHostBuilder builder)
    {
        var host = base.CreateHost(builder);
        using var scope = host.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<BridgePdxDbContext>();
        dbContext.Database.EnsureCreated();
        dbContext.Resources.AddRange(TestResources());
        dbContext.SaveChanges();
        return host;
    }

    private static IEnumerable<ResourceEntity> TestResources()
    {
        yield return CreateResource(
            "active-food-97201",
            "Sample Active Food Desk",
            "Food",
            "97201",
            isOpenNow: true,
            isWheelchairAccessible: true,
            isActive: true
        );
        yield return CreateResource(
            "active-food-97205",
            "Sample Closed Food Desk",
            "Food",
            "97205",
            isOpenNow: false,
            isWheelchairAccessible: false,
            isActive: true
        );
        yield return CreateResource(
            "active-housing-97201",
            "Sample Housing Desk",
            "Housing",
            "97201",
            isOpenNow: true,
            isWheelchairAccessible: false,
            isActive: true
        );
        yield return CreateResource(
            "inactive-food-97201",
            "Sample Inactive Food Desk",
            "Food",
            "97201",
            isOpenNow: true,
            isWheelchairAccessible: true,
            isActive: false
        );
    }

    private static ResourceEntity CreateResource(
        string id,
        string name,
        string category,
        string zipCode,
        bool isOpenNow,
        bool isWheelchairAccessible,
        bool isActive
    ) => new()
    {
        Id = id,
        Name = name,
        Category = category,
        Description = "Fictional integration-test resource.",
        StreetAddress = "999 Test Example Way",
        City = "Portland",
        State = "OR",
        ZipCode = zipCode,
        Phone = "(503) 555-0199",
        Website = $"https://{id}.example.org",
        Hours = "Sample hours only",
        Eligibility = "Sample eligibility only",
        DocumentsToBring = ["Sample document"],
        ServicesOffered = ["Sample service"],
        LanguagesSupported = ["English"],
        AccessibilityInformation = "Sample accessibility information.",
        IsOpenNow = isOpenNow,
        IsWheelchairAccessible = isWheelchairAccessible,
        LastVerified = new DateOnly(2026, 9, 15),
        IsActive = isActive,
    };
}
