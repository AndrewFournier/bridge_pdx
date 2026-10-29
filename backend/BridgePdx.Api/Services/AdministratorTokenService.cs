using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BridgePdx.Api.Entities;
using BridgePdx.Api.Models;
using Microsoft.IdentityModel.Tokens;

namespace BridgePdx.Api.Services;

public sealed class AdministratorTokenService(IConfiguration configuration, TimeProvider timeProvider)
{
    public AdministratorLoginResponse CreateToken(AdministratorUser administrator)
    {
        var issuer = configuration["Jwt:Issuer"]!;
        var audience = configuration["Jwt:Audience"]!;
        var signingKey = configuration["Jwt:SigningKey"]!;
        var lifetimeMinutes = configuration.GetValue("Jwt:LifetimeMinutes", 15);
        var now = timeProvider.GetUtcNow();
        var expires = now.AddMinutes(Math.Clamp(lifetimeMinutes, 1, 60));
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, administrator.Id),
            new Claim(JwtRegisteredClaimNames.Email, administrator.Email!),
            new Claim(ClaimTypes.NameIdentifier, administrator.Id),
            new Claim(ClaimTypes.Role, "Administrator"),
        };
        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)),
            SecurityAlgorithms.HmacSha256
        );
        var token = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            now.UtcDateTime,
            expires.UtcDateTime,
            credentials
        );
        return new AdministratorLoginResponse(
            new JwtSecurityTokenHandler().WriteToken(token),
            expires,
            "Bearer"
        );
    }
}
