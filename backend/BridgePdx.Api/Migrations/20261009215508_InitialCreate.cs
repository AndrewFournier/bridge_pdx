using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BridgePdx.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Resources",
                columns: table => new
                {
                    Id = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: false),
                    StreetAddress = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    City = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    State = table.Column<string>(type: "character varying(2)", maxLength: 2, nullable: false),
                    ZipCode = table.Column<string>(type: "character varying(5)", maxLength: 5, nullable: false),
                    Phone = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Website = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Hours = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Eligibility = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    DocumentsToBring = table.Column<string[]>(type: "text[]", nullable: false),
                    ServicesOffered = table.Column<string[]>(type: "text[]", nullable: false),
                    LanguagesSupported = table.Column<string[]>(type: "text[]", nullable: false),
                    AccessibilityInformation = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    IsOpenNow = table.Column<bool>(type: "boolean", nullable: false),
                    IsWheelchairAccessible = table.Column<bool>(type: "boolean", nullable: false),
                    LastVerified = table.Column<DateOnly>(type: "date", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Resources", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Resources_Category",
                table: "Resources",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_Resources_IsActive",
                table: "Resources",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_Resources_ZipCode",
                table: "Resources",
                column: "ZipCode");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Resources");
        }
    }
}
