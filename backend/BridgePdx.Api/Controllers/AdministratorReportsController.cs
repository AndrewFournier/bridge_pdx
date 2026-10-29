using System.Security.Claims;
using BridgePdx.Api.Data;
using BridgePdx.Api.Entities;
using BridgePdx.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BridgePdx.Api.Controllers;

[ApiController]
[Authorize(Policy = "Administrator")]
[Route("api/admin/reports")]
[ApiExplorerSettings(GroupName = "administrator")]
public sealed class AdministratorReportsController(
    BridgePdxDbContext dbContext,
    TimeProvider timeProvider
) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedAdminReportsResponse>> GetAll(
        [FromQuery] AdminReportQueryParameters parameters,
        CancellationToken cancellationToken
    )
    {
        var query = dbContext.ResourceReports.AsNoTracking().Include(report => report.Resource).AsQueryable();
        if (!string.IsNullOrWhiteSpace(parameters.Status))
        {
            if (!ReportStatusCodes.TryParse(parameters.Status, out var status))
                return InvalidFilter(nameof(parameters.Status), "Use a supported report status.");
            query = query.Where(report => report.Status == status);
        }
        if (!string.IsNullOrWhiteSpace(parameters.Reason))
        {
            if (!ReportReasonCodes.TryParse(parameters.Reason, out var reason))
                return InvalidFilter(nameof(parameters.Reason), "Use a supported report reason.");
            query = query.Where(report => report.Reason == reason);
        }
        if (!string.IsNullOrWhiteSpace(parameters.ResourceId))
            query = query.Where(report => report.ResourceId == parameters.ResourceId);
        if (parameters.SubmittedFromUtc is not null)
            query = query.Where(report => report.SubmittedAtUtc >= parameters.SubmittedFromUtc);
        if (parameters.SubmittedToUtc is not null)
            query = query.Where(report => report.SubmittedAtUtc <= parameters.SubmittedToUtc);

        var totalCount = await query.CountAsync(cancellationToken);
        var reportEntities = await query
            .OrderByDescending(report => report.SubmittedAtUtc)
            .ThenByDescending(report => report.Id)
            .Skip((parameters.Page - 1) * parameters.PageSize)
            .Take(parameters.PageSize)
            .ToListAsync(cancellationToken);
        var reports = reportEntities.Select(ToResponse).ToList();
        return Ok(new PagedAdminReportsResponse(reports, parameters.Page, parameters.PageSize, totalCount));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<AdminReportResponse>> GetById(
        Guid id,
        CancellationToken cancellationToken
    )
    {
        var report = await dbContext.ResourceReports
            .AsNoTracking()
            .Include(item => item.Resource)
            .SingleOrDefaultAsync(item => item.Id == id, cancellationToken);
        return report is null ? NotFound() : Ok(ToResponse(report));
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<ActionResult<AdminReportResponse>> UpdateStatus(
        Guid id,
        UpdateReportStatusRequest request,
        CancellationToken cancellationToken
    )
    {
        if (!ReportStatusCodes.TryParse(request.Status, out var nextStatus))
            return InvalidFilter(nameof(request.Status), "Use a supported report status.");

        var report = await dbContext.ResourceReports
            .Include(item => item.Resource)
            .SingleOrDefaultAsync(item => item.Id == id, cancellationToken);
        if (report is null) return NotFound();
        if (!IsAllowedTransition(report.Status, nextStatus))
        {
            ModelState.AddModelError(nameof(request.Status), "The requested status transition is not allowed.");
            return ValidationProblem(ModelState);
        }

        report.Status = nextStatus;
        report.ReviewedAtUtc = timeProvider.GetUtcNow();
        report.ReviewingAdministratorId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(ToResponse(report));
    }

    private ActionResult InvalidFilter(string field, string message)
    {
        ModelState.AddModelError(field, message);
        return ValidationProblem(ModelState);
    }

    private static bool IsAllowedTransition(ReportReviewStatus current, ReportReviewStatus next) =>
        (current, next) switch
        {
            (ReportReviewStatus.Pending, ReportReviewStatus.Reviewed) => true,
            (ReportReviewStatus.Pending, ReportReviewStatus.Dismissed) => true,
            (ReportReviewStatus.Reviewed, ReportReviewStatus.Resolved) => true,
            (ReportReviewStatus.Reviewed, ReportReviewStatus.Dismissed) => true,
            _ => false,
        };

    private static AdminReportResponse ToResponse(ResourceReportEntity report) =>
        new(
            report.Id,
            report.Reason.ToCode(),
            report.Details,
            report.Status.ToCode(),
            report.SubmittedAtUtc,
            report.ReviewedAtUtc,
            report.ReviewingAdministratorId,
            new AdminReportResourceResponse(
                report.Resource.Id,
                report.Resource.Name,
                report.Resource.Category,
                report.Resource.StreetAddress,
                report.Resource.City,
                report.Resource.State,
                report.Resource.ZipCode
            )
        );
}
