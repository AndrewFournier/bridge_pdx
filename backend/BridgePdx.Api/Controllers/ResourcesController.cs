using BridgePdx.Api.Data;
using BridgePdx.Api.Entities;
using BridgePdx.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BridgePdx.Api.Controllers;

[ApiController]
[Route("api/resources")]
public sealed class ResourcesController(BridgePdxDbContext dbContext) : ControllerBase
{
    /// <summary>Returns active resources matching all supplied filters.</summary>
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<ResourceResponse>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<IReadOnlyList<ResourceResponse>>> GetResources(
        [FromQuery] ResourceQueryParameters filters,
        CancellationToken cancellationToken
    )
    {
        var query = dbContext.Resources.AsNoTracking().Where(resource => resource.IsActive);

        if (!string.IsNullOrWhiteSpace(filters.Category))
        {
            var category = filters.Category.Trim().ToLower();
            query = query.Where(resource => resource.Category.ToLower() == category);
        }

        if (filters.ZipCode is not null)
        {
            query = query.Where(resource => resource.ZipCode == filters.ZipCode);
        }

        if (filters.OpenNow is not null)
        {
            query = query.Where(resource => resource.IsOpenNow == filters.OpenNow);
        }

        if (filters.WheelchairAccessible is not null)
        {
            query = query.Where(resource =>
                resource.IsWheelchairAccessible == filters.WheelchairAccessible
            );
        }

        var resources = await query
            .OrderBy(resource => resource.Name)
            .Select(resource => ToResponse(resource))
            .ToListAsync(cancellationToken);

        return Ok(resources);
    }

    /// <summary>Returns one active resource by its stable ID.</summary>
    [HttpGet("{id}")]
    [ProducesResponseType<ResourceResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ResourceResponse>> GetResource(
        string id,
        CancellationToken cancellationToken
    )
    {
        var resource = await dbContext.Resources
            .AsNoTracking()
            .Where(item => item.IsActive && item.Id == id)
            .Select(item => ToResponse(item))
            .SingleOrDefaultAsync(cancellationToken);

        return resource is null ? NotFound() : Ok(resource);
    }

    private static ResourceResponse ToResponse(ResourceEntity resource) => new(
        resource.Id,
        resource.Name,
        resource.Category,
        resource.Description,
        resource.StreetAddress,
        resource.City,
        resource.State,
        resource.ZipCode,
        resource.Phone,
        resource.Website,
        resource.Hours,
        resource.Eligibility,
        resource.DocumentsToBring,
        resource.ServicesOffered,
        resource.LanguagesSupported,
        resource.AccessibilityInformation,
        resource.IsOpenNow,
        resource.IsWheelchairAccessible,
        resource.LastVerified,
        resource.IsActive
    );
}
