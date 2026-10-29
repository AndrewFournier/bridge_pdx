using System.ComponentModel.DataAnnotations;

namespace BridgePdx.Api.Models;

public sealed class AdministratorLoginRequest
{
    [Required, EmailAddress]
    public string? Email { get; init; }

    [Required]
    public string? Password { get; init; }
}

public sealed record AdministratorLoginResponse(
    string AccessToken,
    DateTimeOffset ExpiresAtUtc,
    string TokenType
);

public sealed record AdministratorProfileResponse(string Id, string Email);
