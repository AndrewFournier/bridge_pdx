using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BridgePdx.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddResourceReports : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ResourceReports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ResourceId = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Reason = table.Column<string>(type: "text", nullable: false),
                    Details = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    SubmittedAtUtc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ResourceReports", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ResourceReports_Resources_ResourceId",
                        column: x => x.ResourceId,
                        principalTable: "Resources",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ResourceReports_ResourceId",
                table: "ResourceReports",
                column: "ResourceId");

            migrationBuilder.CreateIndex(
                name: "IX_ResourceReports_Status",
                table: "ResourceReports",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_ResourceReports_SubmittedAtUtc",
                table: "ResourceReports",
                column: "SubmittedAtUtc");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ResourceReports");
        }
    }
}
