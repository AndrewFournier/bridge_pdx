using System.Security.Claims;
using BridgePdx.Api.Data;
using BridgePdx.Api.Entities;
using BridgePdx.Api.Models;
using BridgePdx.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace BridgePdx.Api.Controllers;

[ApiController]
[Route("api/admin/auth")]
[ApiExplorerSettings(GroupName = "administrator")]
public sealed class AdministratorAuthController(
    UserManager<AdministratorUser> userManager,
    IPasswordHasher<AdministratorUser> passwordHasher,
    AdministratorTokenService tokenService
) : ControllerBase
{
    private static readonly AdministratorUser DummyUser = new() { Email = "nobody@example.invalid" };
    private static readonly string DummyPasswordHash = new PasswordHasher<AdministratorUser>()
        .HashPassword(DummyUser, "Never-A-Real-Password-123!");

    [AllowAnonymous]
    [HttpPost("login")]
    [EnableRateLimiting("AdministratorLogin")]
    [ProducesResponseType<AdministratorLoginResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    public async Task<ActionResult<AdministratorLoginResponse>> Login(
        AdministratorLoginRequest request
    )
    {
        const string genericError = "Invalid email or password.";
        var email = request.Email!.Trim();
        var administrator = await userManager.FindByEmailAsync(email);
        if (administrator is null)
        {
            passwordHasher.VerifyHashedPassword(DummyUser, DummyPasswordHash, request.Password!);
            return Unauthorized(new { error = genericError });
        }

        if (await userManager.IsLockedOutAsync(administrator))
        {
            return Unauthorized(new { error = genericError });
        }

        if (!await userManager.CheckPasswordAsync(administrator, request.Password!))
        {
            await userManager.AccessFailedAsync(administrator);
            return Unauthorized(new { error = genericError });
        }

        if (!await userManager.IsInRoleAsync(administrator, DevelopmentAdministratorBootstrapper.RoleName))
        {
            return Unauthorized(new { error = genericError });
        }

        await userManager.ResetAccessFailedCountAsync(administrator);
        return Ok(tokenService.CreateToken(administrator));
    }

    [Authorize(Policy = "Administrator")]
    [HttpGet("me")]
    [ProducesResponseType<AdministratorProfileResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<AdministratorProfileResponse>> Me()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var administrator = await userManager.FindByIdAsync(id);
        if (administrator?.Email is null) return Unauthorized();
        return Ok(new AdministratorProfileResponse(administrator.Id, administrator.Email));
    }
}
