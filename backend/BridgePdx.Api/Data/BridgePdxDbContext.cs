using BridgePdx.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace BridgePdx.Api.Data;

public sealed class BridgePdxDbContext(DbContextOptions<BridgePdxDbContext> options)
    : DbContext(options)
{
    public DbSet<ResourceEntity> Resources => Set<ResourceEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var resource = modelBuilder.Entity<ResourceEntity>();
        resource.ToTable("Resources");
        resource.HasIndex(item => item.Category);
        resource.HasIndex(item => item.ZipCode);
        resource.HasIndex(item => item.IsActive);
        resource.Property(item => item.DocumentsToBring).HasColumnType("text[]");
        resource.Property(item => item.ServicesOffered).HasColumnType("text[]");
        resource.Property(item => item.LanguagesSupported).HasColumnType("text[]");
    }
}
