using BridgePdx.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace BridgePdx.Api.Data;

public sealed class BridgePdxDbContext(DbContextOptions<BridgePdxDbContext> options)
    : DbContext(options)
{
    public DbSet<ResourceEntity> Resources => Set<ResourceEntity>();
    public DbSet<ResourceReportEntity> ResourceReports => Set<ResourceReportEntity>();

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

        var report = modelBuilder.Entity<ResourceReportEntity>();
        report.ToTable("ResourceReports");
        report.Property(item => item.Reason).HasConversion<string>();
        report.Property(item => item.Status).HasConversion<string>();
        report.HasIndex(item => item.ResourceId);
        report.HasIndex(item => item.Status);
        report.HasIndex(item => item.SubmittedAtUtc);
        report
            .HasOne(item => item.Resource)
            .WithMany(item => item.Reports)
            .HasForeignKey(item => item.ResourceId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
