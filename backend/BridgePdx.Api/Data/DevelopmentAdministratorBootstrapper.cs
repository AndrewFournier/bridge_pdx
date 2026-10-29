using BridgePdx.Api.Entities;
using Microsoft.AspNetCore.Identity;

namespace BridgePdx.Api.Data;

public static class DevelopmentAdministratorBootstrapper
{
    public const string RoleName = "Administrator";

    public static async Task BootstrapAsync(IServiceProvider services, IConfiguration configuration)
    {
        var email = configuration["DevelopmentAdministrator:Email"];
        var password = configuration["DevelopmentAdministrator:Password"];
        if (string.IsNullOrWhiteSpace(email) && string.IsNullOrWhiteSpace(password)) return;
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            throw new InvalidOperationException(
                "Both DevelopmentAdministrator:Email and DevelopmentAdministrator:Password must be supplied."
            );
        }

        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        if (!await roleManager.RoleExistsAsync(RoleName))
        {
            var roleResult = await roleManager.CreateAsync(new IdentityRole(RoleName));
            EnsureSucceeded(roleResult, "create the Administrator role");
        }

        var userManager = services.GetRequiredService<UserManager<AdministratorUser>>();
        var existing = await userManager.FindByEmailAsync(email);
        if (existing is not null) return;

        var administrator = new AdministratorUser
        {
            UserName = email.Trim(),
            Email = email.Trim(),
            EmailConfirmed = true,
        };
        EnsureSucceeded(
            await userManager.CreateAsync(administrator, password),
            "create the development administrator"
        );
        EnsureSucceeded(
            await userManager.AddToRoleAsync(administrator, RoleName),
            "assign the Administrator role"
        );
    }

    private static void EnsureSucceeded(IdentityResult result, string operation)
    {
        if (result.Succeeded) return;
        var errors = string.Join("; ", result.Errors.Select(error => error.Description));
        throw new InvalidOperationException($"Unable to {operation}: {errors}");
    }
}
