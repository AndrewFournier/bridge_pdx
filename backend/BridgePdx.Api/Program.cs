using BridgePdx.Api.Data;
using Microsoft.EntityFrameworkCore;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddProblemDetails();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSingleton(TimeProvider.System);
var reportPermitLimit = builder.Configuration.GetValue("RateLimiting:ReportSubmission:PermitLimit", 10);
var reportWindowSeconds = builder.Configuration.GetValue("RateLimiting:ReportSubmission:WindowSeconds", 60);
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
}
else
{
    app.UseExceptionHandler();
}

if (!app.Environment.IsDevelopment() && !app.Environment.IsEnvironment("Testing"))
{
    app.UseHttpsRedirection();
}

app.UseRateLimiter();

app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "Healthy" }))
    .WithName("Health")
    .WithSummary("Reports whether the API process is healthy.")
    .Produces(StatusCodes.Status200OK);

app.Run();

public partial class Program;
