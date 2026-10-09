# BridgePDX

BridgePDX is a Flutter community-resource prototype with an ASP.NET Core API foundation. The Flutter application still uses its local sample data and is **not connected to the backend** in this milestone.

All current listings, organizations, addresses, phone numbers, websites, eligibility details, and schedules are fictional development data. They are not verified real-world services.

## Architecture

- `lib/` and `test/`: Flutter Material 3 application and widget tests.
- `backend/BridgePdx.Api`: .NET 10 ASP.NET Core Web API, EF Core, PostgreSQL configuration, development seed data, health check, and Swagger UI.
- `backend/BridgePdx.Api.Tests`: isolated HTTP integration tests using EF Core's in-memory provider. PostgreSQL and Docker are not required for tests.
- `backend/BridgePdx.Backend.sln`: backend solution containing both .NET projects.
- `backend/compose.yaml`: optional local PostgreSQL 17 development service with a named data volume and health check.

The API keeps its persistence entity separate from its public response model so internal database concerns are not exposed unnecessarily.

## Prerequisites

- Flutter SDK compatible with the version in `.metadata`
- .NET 10 SDK (LTS)
- PostgreSQL 17 or another supported PostgreSQL version, either installed manually or run with Docker Compose
- Docker Desktop or another Compose-compatible runtime only if using the Docker option

## Start PostgreSQL

Docker Compose uses development-only placeholder credentials and does not start automatically:

```sh
cd backend
docker compose up -d postgres
docker compose ps
```

Database contents persist in the named `bridgepdx_postgres_data` volume. Stop the service with `docker compose down`; this preserves the named volume.

For a manually installed PostgreSQL server, create an equivalent development user and database:

```sql
CREATE USER bridgepdx_dev WITH PASSWORD 'development_only_change_me';
CREATE DATABASE bridgepdx_dev OWNER bridgepdx_dev;
```

The placeholder password must not be reused outside local development.

## Configure the connection safely

`appsettings.Development.json` contains only the Compose-compatible local placeholder connection. Production configuration contains no connection string and fails closed when one is missing.

Override any connection string with an environment variable rather than committing a secret:

```sh
export ConnectionStrings__BridgePdx='Host=localhost;Port=5432;Database=bridgepdx_dev;Username=bridgepdx_dev;Password=your-local-password'
```

For deployed environments, provide `ConnectionStrings__BridgePdx` through the hosting platform's secret manager. Swagger, development seeding, automatic migration, and Flutter-development CORS are enabled only in the Development environment.

## Restore tools and apply migrations

From the repository root:

```sh
dotnet tool restore --tool-manifest backend/dotnet-tools.json
dotnet tool run dotnet-ef --tool-manifest backend/dotnet-tools.json -- database update --project backend/BridgePdx.Api/BridgePdx.Api.csproj --startup-project backend/BridgePdx.Api/BridgePdx.Api.csproj
```

The API also applies pending migrations and inserts clearly fictional seed resources when it starts in Development. The seeder is idempotent and is not run in production or tests.

## Run the API and Swagger

```sh
dotnet run --project backend/BridgePdx.Api/BridgePdx.Api.csproj
```

Use the HTTP or HTTPS address printed by `dotnet run`, then open `/swagger` in a browser. The development CORS allowlist is limited to the explicit localhost origins in `appsettings.Development.json`; no unrestricted production CORS policy is registered.

Available routes:

- `GET /health`
- `GET /api/resources`
- `GET /api/resources/{id}`

The collection route accepts combinable `category`, `zipCode`, `openNow`, and `wheelchairAccessible` query parameters. Resource routes return active listings only.

## Run tests and checks

Backend tests do not use the developer's PostgreSQL instance, Docker, the network, or the real clock:

```sh
dotnet build backend/BridgePdx.Backend.sln
dotnet test backend/BridgePdx.Backend.sln
flutter analyze
flutter test
```
