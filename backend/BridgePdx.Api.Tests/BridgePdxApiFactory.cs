using BridgePdx.Api.Data;
using BridgePdx.Api.Entities;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
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
                    ["Jwt:Issuer"] = "BridgePdx.Api.Tests",
                    ["Jwt:Audience"] = "BridgePdx.Api.Tests.Client",
                    ["Jwt:SigningKey"] = "test-only-signing-key-with-at-least-32-characters",
                    ["Jwt:LifetimeMinutes"] = "15",
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
            var fixedTimeProvider = new FixedTimeProvider(
                new DateTimeOffset(2026, 10, 9, 12, 0, 0, TimeSpan.Zero)
            );
            services.RemoveAll<TimeProvider>();
            services.AddSingleton<TimeProvider>(fixedTimeProvider);
            services.PostConfigure<JwtBearerOptions>(
                JwtBearerDefaults.AuthenticationScheme,
                options => options.TokenValidationParameters.LifetimeValidator =
                    (notBefore, expires, _, _) =>
                        notBefore <= fixedTimeProvider.GetUtcNow().UtcDateTime
                        && expires >= fixedTimeProvider.GetUtcNow().UtcDateTime
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
        SeedAdministrators(scope.ServiceProvider).GetAwaiter().GetResult();
        SeedReports(dbContext);
        return host;
    }

    public static readonly Guid PendingReportId = Guid.Parse("10000000-0000-0000-0000-000000000001");
    public static readonly Guid ReviewedReportId = Guid.Parse("10000000-0000-0000-0000-000000000002");
    public const string AdministratorEmail = "admin@example.invalid";
    public const string AdministratorPassword = "Test-Administrator-Password-123!";

    private static async Task SeedAdministrators(IServiceProvider services)
    {
        var roleManager = services.GetRequiredService<Microsoft.AspNetCore.Identity.RoleManager<Microsoft.AspNetCore.Identity.IdentityRole>>();
        await roleManager.CreateAsync(new Microsoft.AspNetCore.Identity.IdentityRole("Administrator"));
        var userManager = services.GetRequiredService<Microsoft.AspNetCore.Identity.UserManager<AdministratorUser>>();
        var administrator = new AdministratorUser
        {
            Id = "test-administrator",
            UserName = AdministratorEmail,
            Email = AdministratorEmail,
            EmailConfirmed = true,
        };
        await userManager.CreateAsync(administrator, AdministratorPassword);
        await userManager.AddToRoleAsync(administrator, "Administrator");
        await userManager.CreateAsync(
            new AdministratorUser
            {
                Id = "test-non-administrator",
                UserName = "viewer@example.invalid",
                Email = "viewer@example.invalid",
                EmailConfirmed = true,
            },
            AdministratorPassword
        );
    }

    private static void SeedReports(BridgePdxDbContext dbContext)
    {
        dbContext.ResourceReports.AddRange(
            new ResourceReportEntity
            {
                Id = PendingReportId,
                ResourceId = "active-food-97201",
                Resource = dbContext.Resources.Find("active-food-97201")!,
                Reason = ReportReason.IncorrectHours,
                Details = "Sample pending report",
                SubmittedAtUtc = new DateTimeOffset(2026, 10, 8, 12, 0, 0, TimeSpan.Zero),
                Status = ReportReviewStatus.Pending,
            },
            new ResourceReportEntity
            {
                Id = ReviewedReportId,
                ResourceId = "active-housing-97201",
                Resource = dbContext.Resources.Find("active-housing-97201")!,
                Reason = ReportReason.IncorrectAddress,
                Details = "Sample reviewed report",
                SubmittedAtUtc = new DateTimeOffset(2026, 10, 7, 12, 0, 0, TimeSpan.Zero),
                Status = ReportReviewStatus.Reviewed,
                ReviewedAtUtc = new DateTimeOffset(2026, 10, 8, 8, 0, 0, TimeSpan.Zero),
                ReviewingAdministratorId = "test-administrator",
            }
        );
        dbContext.SaveChanges();
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

    private sealed class FixedTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => utcNow;
    }
}
