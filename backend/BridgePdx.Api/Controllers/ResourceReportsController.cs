using BridgePdx.Api.Data;
using BridgePdx.Api.Entities;
using BridgePdx.Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace BridgePdx.Api.Controllers;

[ApiController]
[Route("api/resources/{resourceId}/reports")]
public sealed class ResourceReportsController(
    BridgePdxDbContext dbContext,
    TimeProvider timeProvider
) : ControllerBase
{
    [HttpPost]
    [EnableRateLimiting("ReportSubmission")]
    [ProducesResponseType<ResourceReportResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    public async Task<ActionResult<ResourceReportResponse>> Create(
        string resourceId,
        CreateResourceReportRequest request,
        CancellationToken cancellationToken
    )
    {
        if (!ReportReasonCodes.TryParse(request.Reason, out var reason))
        {
            ModelState.AddModelError(nameof(request.Reason), "Use a supported report reason code.");
            return ValidationProblem(ModelState);
        }

        var resourceExists = await dbContext.Resources.AnyAsync(
            item => item.Id == resourceId && item.IsActive,
            cancellationToken
        );
        if (!resourceExists)
        {
            return NotFound();
        }

        var details = request.Details?.Trim();
        if (string.IsNullOrWhiteSpace(details)) details = null;

        var report = new ResourceReportEntity
        {
            Id = Guid.NewGuid(),
            ResourceId = resourceId,
            Resource = null!,
            Reason = reason,
            Details = details,
            SubmittedAtUtc = timeProvider.GetUtcNow(),
            Status = ReportReviewStatus.Pending,
        };
        dbContext.ResourceReports.Add(report);
        await dbContext.SaveChangesAsync(cancellationToken);

        var response = new ResourceReportResponse(
            report.Id,
            report.ResourceId,
            report.Reason.ToCode(),
            report.Details,
            report.SubmittedAtUtc,
            "pending"
        );
        return Created($"/api/resources/{resourceId}", response);
    }
}
