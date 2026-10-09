using System.Net;
using System.Net.Http.Json;
using BridgePdx.Api.Models;

namespace BridgePdx.Api.Tests;

public sealed class ResourcesApiTests(BridgePdxApiFactory factory)
    : IClassFixture<BridgePdxApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Collection_ReturnsOnlyActiveResources()
    {
        var resources = await GetResourcesAsync("/api/resources");

        Assert.Equal(3, resources.Count);
        Assert.DoesNotContain(resources, item => item.Id == "inactive-food-97201");
    }

    [Fact]
    public async Task Collection_FiltersByCategory()
    {
        var resources = await GetResourcesAsync("/api/resources?category=food");

        Assert.Equal(2, resources.Count);
        Assert.All(resources, item => Assert.Equal("Food", item.Category));
    }

    [Fact]
    public async Task Collection_FiltersByZipCode()
    {
        var resources = await GetResourcesAsync("/api/resources?zipCode=97201");

        Assert.Equal(2, resources.Count);
        Assert.All(resources, item => Assert.Equal("97201", item.ZipCode));
    }

    [Fact]
    public async Task Collection_CombinesFilters()
    {
        var resources = await GetResourcesAsync(
            "/api/resources?category=Food&zipCode=97201&openNow=true&wheelchairAccessible=true"
        );

        var resource = Assert.Single(resources);
        Assert.Equal("active-food-97201", resource.Id);
    }

    [Fact]
    public async Task Item_ReturnsActiveResourceById()
    {
        var resource = await _client.GetFromJsonAsync<ResourceResponse>(
            "/api/resources/active-food-97201"
        );

        Assert.NotNull(resource);
        Assert.Equal("Sample Active Food Desk", resource.Name);
    }

    [Fact]
    public async Task Item_ReturnsNotFoundForUnknownId()
    {
        var response = await _client.GetAsync("/api/resources/does-not-exist");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Item_ReturnsNotFoundForInactiveResource()
    {
        var response = await _client.GetAsync("/api/resources/inactive-food-97201");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Health_ReturnsSuccess()
    {
        var response = await _client.GetAsync("/health");

        response.EnsureSuccessStatusCode();
    }

    private async Task<IReadOnlyList<ResourceResponse>> GetResourcesAsync(string path)
    {
        var resources = await _client.GetFromJsonAsync<List<ResourceResponse>>(path);
        return Assert.IsType<List<ResourceResponse>>(resources);
    }
}
