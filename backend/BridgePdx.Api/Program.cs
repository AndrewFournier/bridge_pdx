using BridgePdx.Api.Data;
using BridgePdx.Api.Entities;
using BridgePdx.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using System.Text;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddProblemDetails();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.DocInclusionPredicate((_, _) => true);
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Administrator bearer token. Enter the token without placing it in a URL.",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
    });
    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document, null)] = [],
    });
});
builder.Services.AddSingleton(TimeProvider.System);
var reportPermitLimit = builder.Configuration.GetValue("RateLimiting:ReportSubmission:PermitLimit", 10);
var reportWindowSeconds = builder.Configuration.GetValue("RateLimiting:ReportSubmission:WindowSeconds", 60);
var loginPermitLimit = builder.Configuration.GetValue("RateLimiting:AdministratorLogin:PermitLimit", 10);
var loginWindowSeconds = builder.Configuration.GetValue("RateLimiting:AdministratorLogin:WindowSeconds", 60);
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("ReportSubmission", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            $"{context.Connection.RemoteIpAddress}:{context.Request.RouteValues["resourceId"]}",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = Math.Max(1, reportPermitLimit),
                Window = TimeSpan.FromSeconds(Math.Max(1, reportWindowSeconds)),
                QueueLimit = 0,
                AutoReplenishment = true,
            }
        )
    );
    options.AddPolicy("AdministratorLogin", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown-client",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = Math.Max(1, loginPermitLimit),
                Window = TimeSpan.FromSeconds(Math.Max(1, loginWindowSeconds)),
                QueueLimit = 0,
                AutoReplenishment = true,
            }
        )
    );
});

var connectionString = builder.Configuration.GetConnectionString("BridgePdx");
if (connectionString is null && !builder.Environment.IsEnvironment("Testing"))
{
    throw new InvalidOperationException(
        "Connection string 'BridgePdx' is not configured."
    );
}

connectionString ??= "Host=unused-for-tests";
builder.Services.AddDbContext<BridgePdxDbContext>(options =>
    options.UseNpgsql(connectionString)
);
builder.Services
    .AddIdentityCore<AdministratorUser>(options =>
    {
        options.User.RequireUniqueEmail = true;
        options.Password.RequiredLength = 12;
        options.Password.RequireDigit = true;
        options.Password.RequireLowercase = true;
        options.Password.RequireUppercase = true;
        options.Password.RequireNonAlphanumeric = true;
        options.Lockout.AllowedForNewUsers = true;
        options.Lockout.MaxFailedAccessAttempts = 5;
        options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    })
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<BridgePdxDbContext>()
    .AddDefaultTokenProviders();

var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];
var jwtSigningKey = builder.Configuration["Jwt:SigningKey"];
if (builder.Environment.IsEnvironment("Testing"))
{
    jwtIssuer = "BridgePdx.Api.Tests";
    jwtAudience = "BridgePdx.Api.Tests.Client";
    jwtSigningKey = "test-only-signing-key-with-at-least-32-characters";
}
if (
    string.IsNullOrWhiteSpace(jwtIssuer)
    || string.IsNullOrWhiteSpace(jwtAudience)
    || string.IsNullOrWhiteSpace(jwtSigningKey)
    || jwtSigningKey.Length < 32
)
{
    throw new InvalidOperationException(
        "Jwt:Issuer, Jwt:Audience, and a Jwt:SigningKey of at least 32 characters are required."
    );
}
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSigningKey!)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30),
            NameClaimType = "sub",
            RoleClaimType = System.Security.Claims.ClaimTypes.Role,
        };
    });
builder.Services.AddAuthorization(options =>
    options.AddPolicy(
        "Administrator",
        policy => policy.RequireAuthenticatedUser().RequireRole(DevelopmentAdministratorBootstrapper.RoleName)
    )
);
builder.Services.AddScoped<AdministratorTokenService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterDevelopment", policy =>
    {
        var origins = builder.Configuration
            .GetSection("Cors:DevelopmentOrigins")
            .Get<string[]>() ?? [];
        policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseCors("FlutterDevelopment");

    await using var scope = app.Services.CreateAsyncScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<BridgePdxDbContext>();
    await dbContext.Database.MigrateAsync();
    await DevelopmentDataSeeder.SeedAsync(dbContext);
    await DevelopmentAdministratorBootstrapper.BootstrapAsync(
        scope.ServiceProvider,
        builder.Configuration
    );
}
else if (!app.Environment.IsEnvironment("Testing"))
{
    app.UseExceptionHandler();
}

if (!app.Environment.IsDevelopment() && !app.Environment.IsEnvironment("Testing"))
{
    app.UseHttpsRedirection();
}

app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "Healthy" }))
    .WithName("Health")
    .WithSummary("Reports whether the API process is healthy.")
    .Produces(StatusCodes.Status200OK);

app.Run();

public partial class Program;
