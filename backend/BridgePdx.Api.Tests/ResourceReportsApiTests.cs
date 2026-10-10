using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using BridgePdx.Api.Data;
using BridgePdx.Api.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BridgePdx.Api.Tests;

public sealed class ResourceReportsApiTests(BridgePdxApiFactory factory)
    : IClassFixture<BridgePdxApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task CreatesAndPersistsPendingAnonymousReport()
    {
        var response = await PostAsync("active-food-97201", "incorrect_hours", "  New hours  ");

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("incorrect_hours", json.GetProperty("reason").GetString());
        Assert.Equal("New hours", json.GetProperty("details").GetString());
        Assert.Equal("pending", json.GetProperty("status").GetString());
        Assert.Equal(TimeSpan.Zero, json.GetProperty("submittedAtUtc").GetDateTimeOffset().Offset);
        Assert.False(json.TryGetProperty("email", out _));
        Assert.False(json.TryGetProperty("name", out _));
        var persistedPropertyNames = typeof(ResourceReportEntity)
            .GetProperties()
            .Select(property => property.Name)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
        Assert.DoesNotContain("Name", persistedPropertyNames);
        Assert.DoesNotContain("Email", persistedPropertyNames);
        Assert.DoesNotContain("Phone", persistedPropertyNames);

        await using var scope = factory.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<BridgePdxDbContext>();
        var stored = await db.ResourceReports.SingleAsync(item => item.Id == json.GetProperty("id").GetGuid());
        Assert.Equal(ReportReviewStatus.Pending, stored.Status);
        Assert.Equal(new DateTimeOffset(2026, 10, 9, 12, 0, 0, TimeSpan.Zero), stored.SubmittedAtUtc);
    }

    [Theory]
    [InlineData("incorrect_hours")]
    [InlineData("incorrect_address")]
    [InlineData("incorrect_phone_or_website")]
    [InlineData("service_no_longer_available")]
    [InlineData("eligibility_incorrect")]
    [InlineData("accessibility_incorrect")]
    [InlineData("other")]
    public async Task AcceptsEverySupportedReason(string reason)
    {
        var response = await PostAsync("active-housing-97201", reason, null);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task NormalizesWhitespaceDetailsToNull()
    {
        var response = await PostAsync("active-food-97205", "other", "   \n ");
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.Equal(JsonValueKind.Null, json.GetProperty("details").ValueKind);
    }

    [Theory]
    [InlineData("{}")]
    [InlineData("{\"reason\":\"not_a_reason\"}")]
    public async Task RejectsMissingOrUnknownReason(string body)
    {
        var response = await _client.PostAsync(
            "/api/resources/active-food-97205/reports",
            new StringContent(body, System.Text.Encoding.UTF8, "application/json")
        );
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task RejectsDetailsLongerThan500Characters()
    {
        var response = await PostAsync("active-food-97205", "other", new string('x', 501));
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Theory]
    [InlineData("missing-resource")]
    [InlineData("inactive-food-97201")]
    public async Task ReturnsNotFoundForUnknownOrInactiveResource(string resourceId)
    {
        var response = await PostAsync(resourceId, "other", null);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task RateLimitsRepeatedSubmissionsForSameResource()
    {
        HttpResponseMessage? response = null;
        for (var index = 0; index < 11; index++)
        {
            response = await PostAsync("rate-limit-resource", "other", null);
        }

        Assert.NotNull(response);
        Assert.Equal(HttpStatusCode.TooManyRequests, response.StatusCode);
    }

    private Task<HttpResponseMessage> PostAsync(string resourceId, string reason, string? details) =>
        _client.PostAsJsonAsync($"/api/resources/{resourceId}/reports", new { reason, details });
}
