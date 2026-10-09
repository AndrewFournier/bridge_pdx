using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace BridgePdx.Api.Data;

public sealed class BridgePdxDbContextFactory : IDesignTimeDbContextFactory<BridgePdxDbContext>
{
    public BridgePdxDbContext CreateDbContext(string[] args)
    {
        var connectionString =
            Environment.GetEnvironmentVariable("ConnectionStrings__BridgePdx")
            ?? "Host=localhost;Port=5432;Database=bridgepdx_dev;Username=bridgepdx_dev;Password=development_only_change_me";
        var options = new DbContextOptionsBuilder<BridgePdxDbContext>()
            .UseNpgsql(connectionString)
            .Options;

        return new BridgePdxDbContext(options);
    }
}
