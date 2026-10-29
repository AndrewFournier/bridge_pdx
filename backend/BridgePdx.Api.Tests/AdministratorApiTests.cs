using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using BridgePdx.Api.Data;
using BridgePdx.Api.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;

namespace BridgePdx.Api.Tests;

public sealed class AdministratorApiTests(BridgePdxApiFactory factory)
    : IClassFixture<BridgePdxApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task ValidAdministratorLoginReturnsShortLivedBearerToken()
    {
        var response = await LoginAsync(BridgePdxApiFactory.AdministratorEmail, BridgePdxApiFactory.AdministratorPassword);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Bearer", json.GetProperty("tokenType").GetString());
        Assert.NotEmpty(json.GetProperty("accessToken").GetString()!);
        Assert.Equal(
            new DateTimeOffset(2026, 10, 9, 12, 15, 0, TimeSpan.Zero),
            json.GetProperty("expiresAtUtc").GetDateTimeOffset()
        );
        Assert.False(json.TryGetProperty("passwordHash", out _));
        Assert.False(json.TryGetProperty("securityStamp", out _));
    }

    [Fact]
    public async Task IncorrectPasswordAndUnknownAccountUseSameGenericResponse()
    {
        var incorrect = await LoginAsync(BridgePdxApiFactory.AdministratorEmail, "Wrong-Password-123!");
        var unknown = await LoginAsync("unknown@example.invalid", "Wrong-Password-123!");
        Assert.Equal(HttpStatusCode.Unauthorized, incorrect.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, unknown.StatusCode);
        Assert.Equal(await incorrect.Content.ReadAsStringAsync(), await unknown.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task MeRequiresAuthenticationAndReturnsSafeProfile()
    {
        Assert.Equal(HttpStatusCode.Unauthorized, (await _client.GetAsync("/api/admin/auth/me")).StatusCode);
        await AuthenticateAsAdministratorAsync();
        var json = await _client.GetFromJsonAsync<JsonElement>("/api/admin/auth/me");
        Assert.Equal("test-administrator", json.GetProperty("id").GetString());
        Assert.Equal(BridgePdxApiFactory.AdministratorEmail, json.GetProperty("email").GetString());
        Assert.False(json.TryGetProperty("passwordHash", out _));
    }

    [Fact]
    public async Task InvalidAndExpiredTokensAreRejected()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "not-a-token");
        Assert.Equal(HttpStatusCode.Unauthorized, (await _client.GetAsync("/api/admin/auth/me")).StatusCode);
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            CreateToken("test-administrator", "Administrator", expires: new DateTime(2026, 10, 9, 11, 0, 0, DateTimeKind.Utc))
        );
        Assert.Equal(HttpStatusCode.Unauthorized, (await _client.GetAsync("/api/admin/auth/me")).StatusCode);
    }

    [Fact]
    public async Task ReportListRequiresAdministratorRole()
    {
        Assert.Equal(HttpStatusCode.Unauthorized, (await _client.GetAsync("/api/admin/reports")).StatusCode);
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            CreateToken("test-non-administrator", role: null)
        );
        Assert.Equal(HttpStatusCode.Forbidden, (await _client.GetAsync("/api/admin/reports")).StatusCode);
    }

    [Fact]
    public async Task AdministratorCanListNewestReportsWithResourceInformation()
    {
        await AuthenticateAsAdministratorAsync();
        var json = await _client.GetFromJsonAsync<JsonElement>("/api/admin/reports");
        Assert.True(json.GetProperty("totalCount").GetInt32() >= 2);
        var items = json.GetProperty("items");
        Assert.True(items.GetArrayLength() >= 2);
        Assert.Equal(BridgePdxApiFactory.PendingReportId, items[0].GetProperty("id").GetGuid());
        Assert.Equal("Sample Active Food Desk", items[0].GetProperty("resource").GetProperty("name").GetString());
    }

    [Fact]
    public async Task PaginationWorksAndMaximumPageSizeIsEnforced()
    {
        await AuthenticateAsAdministratorAsync();
        var json = await _client.GetFromJsonAsync<JsonElement>("/api/admin/reports?page=2&pageSize=1");
        Assert.Equal(2, json.GetProperty("page").GetInt32());
        Assert.Equal(1, json.GetProperty("pageSize").GetInt32());
        Assert.Equal(1, json.GetProperty("items").GetArrayLength());
        Assert.Equal(
            HttpStatusCode.BadRequest,
            (await _client.GetAsync("/api/admin/reports?pageSize=101")).StatusCode
        );
    }

    [Theory]
    [InlineData("status=pending", "status", "pending")]
    [InlineData("reason=incorrect_address", "reason", "incorrect_address")]
    public async Task StatusAndReasonFiltersAreApplied(string query, string property, string expected)
    {
        await AuthenticateAsAdministratorAsync();
        var json = await _client.GetFromJsonAsync<JsonElement>($"/api/admin/reports?{query}");
        Assert.All(
            json.GetProperty("items").EnumerateArray(),
            item => Assert.Equal(expected, item.GetProperty(property).GetString())
        );
    }

    [Fact]
    public async Task ResourceAndSubmissionDateFiltersCanBeCombined()
    {
        await AuthenticateAsAdministratorAsync();
        var json = await _client.GetFromJsonAsync<JsonElement>(
            "/api/admin/reports?resourceId=active-food-97201&submittedFromUtc=2026-10-08T00:00:00Z&submittedToUtc=2026-10-08T23:59:59Z"
        );
        Assert.Equal(1, json.GetProperty("items").GetArrayLength());
        Assert.Equal(BridgePdxApiFactory.PendingReportId, json.GetProperty("items")[0].GetProperty("id").GetGuid());
    }

    [Fact]
    public async Task AdministratorCanGetReportDetails()
    {
        await AuthenticateAsAdministratorAsync();
        var json = await _client.GetFromJsonAsync<JsonElement>(
            $"/api/admin/reports/{BridgePdxApiFactory.PendingReportId}"
        );
        Assert.Equal("Sample pending report", json.GetProperty("details").GetString());
    }

    [Fact]
    public async Task ValidStatusUpdateRecordsReviewerAndUtcTimestamp()
    {
        await AuthenticateAsAdministratorAsync();
        var response = await _client.PatchAsJsonAsync(
            $"/api/admin/reports/{BridgePdxApiFactory.ReviewedReportId}/status",
            new { status = "resolved" }
        );
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        await using var scope = factory.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<BridgePdxDbContext>();
        var report = await db.ResourceReports.SingleAsync(item => item.Id == BridgePdxApiFactory.ReviewedReportId);
        Assert.Equal(ReportReviewStatus.Resolved, report.Status);
        Assert.Equal("test-administrator", report.ReviewingAdministratorId);
        Assert.Equal(new DateTimeOffset(2026, 10, 9, 12, 0, 0, TimeSpan.Zero), report.ReviewedAtUtc);
    }

    [Fact]
    public async Task InvalidStatusAndTransitionReturnValidationErrors()
    {
        await AuthenticateAsAdministratorAsync();
        var invalidValue = await _client.PatchAsJsonAsync(
            $"/api/admin/reports/{BridgePdxApiFactory.ReviewedReportId}/status",
            new { status = "invented" }
        );
        var invalidTransition = await _client.PatchAsJsonAsync(
            $"/api/admin/reports/{BridgePdxApiFactory.ReviewedReportId}/status",
            new { status = "pending" }
        );
        Assert.Equal(HttpStatusCode.BadRequest, invalidValue.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, invalidTransition.StatusCode);
    }

    [Fact]
    public async Task UnknownReportReturnsNotFound()
    {
        await AuthenticateAsAdministratorAsync();
        var id = Guid.Parse("ffffffff-ffff-ffff-ffff-ffffffffffff");
        Assert.Equal(HttpStatusCode.NotFound, (await _client.GetAsync($"/api/admin/reports/{id}")).StatusCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await _client.PatchAsJsonAsync($"/api/admin/reports/{id}/status", new { status = "reviewed" })).StatusCode
        );
    }

    [Fact]
    public async Task PublicResourcesAndAnonymousReportSubmissionRemainAvailable()
    {
        _client.DefaultRequestHeaders.Authorization = null;
        Assert.Equal(HttpStatusCode.OK, (await _client.GetAsync("/api/resources")).StatusCode);
        Assert.Equal(
            HttpStatusCode.Created,
            (
                await _client.PostAsJsonAsync(
                    "/api/resources/active-food-97205/reports",
                    new { reason = "other", details = "Anonymous sample" }
                )
            ).StatusCode
        );
    }

    private Task AuthenticateAsAdministratorAsync()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            CreateToken("test-administrator", "Administrator")
        );
        return Task.CompletedTask;
    }

    private Task<HttpResponseMessage> LoginAsync(string email, string password) =>
        _client.PostAsJsonAsync("/api/admin/auth/login", new { email, password });

    private static string CreateToken(string userId, string? role, DateTime? expires = null)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId),
            new(ClaimTypes.NameIdentifier, userId),
        };
        if (role is not null) claims.Add(new Claim(ClaimTypes.Role, role));
        var token = new JwtSecurityToken(
            "BridgePdx.Api.Tests",
            "BridgePdx.Api.Tests.Client",
            claims,
            new DateTime(2026, 10, 9, 10, 0, 0, DateTimeKind.Utc),
            expires ?? new DateTime(2026, 10, 9, 13, 0, 0, DateTimeKind.Utc),
            new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes("test-only-signing-key-with-at-least-32-characters")),
                SecurityAlgorithms.HmacSha256
            )
        );
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

public sealed class AdministratorLoginRateLimitTests(BridgePdxApiFactory factory)
    : IClassFixture<BridgePdxApiFactory>
{
    [Fact]
    public async Task RepeatedLoginAttemptsAreRateLimited()
    {
        using var client = factory.CreateClient();
        HttpResponseMessage? response = null;
        for (var attempt = 0; attempt < 11; attempt++)
        {
            response = await client.PostAsJsonAsync(
                "/api/admin/auth/login",
                new { email = "rate-limit@example.invalid", password = "Wrong-Password-123!" }
            );
        }
        Assert.NotNull(response);
        Assert.Equal(HttpStatusCode.TooManyRequests, response.StatusCode);
    }
}
