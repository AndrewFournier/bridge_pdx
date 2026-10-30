# BridgePDX

BridgePDX is a Flutter community-resource prototype backed by an ASP.NET Core resource API and PostgreSQL. Flutter screens access the API through an injected repository; local sample data remains isolated to deterministic tests and development utilities.

All current listings, organizations, addresses, phone numbers, websites, eligibility details, and schedules are fictional development data. They are not verified real-world services.

## Architecture

- `lib/` and `test/`: Flutter Material 3 application, HTTP repository, JSON mapping, and deterministic tests with fake repositories.
- `backend/BridgePdx.Api`: .NET 10 ASP.NET Core Web API, EF Core, PostgreSQL configuration, ASP.NET Core Identity administrator accounts, JWT bearer authentication, development seed data, health check, and Swagger UI.
- `backend/BridgePdx.Api.Tests`: isolated HTTP integration tests using EF Core's in-memory provider. PostgreSQL and Docker are not required for tests.
- `backend/BridgePdx.Backend.sln`: backend solution containing both .NET projects.
- `backend/compose.yaml`: optional local PostgreSQL 17 development service with a named data volume and health check.

The API keeps persistence entities separate from public response models so internal database concerns are not exposed unnecessarily. Public users remain account-free. Administrator accounts live in the same PostgreSQL database and use ASP.NET Core Identity password hashing and lockout; there is no public registration endpoint or administrator UI yet.

The normal Flutter application always loads resources through `HttpResourceRepository`. Fictional in-app sample resources are used only by explicitly injected test/development fakes; an API failure is shown to the user with retry guidance and never silently replaced with local results.

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

## Configure administrator authentication

JWT signing material and bootstrap credentials are intentionally absent from tracked configuration. For local development, use .NET user-secrets from the repository root:

```sh
dotnet user-secrets set "Jwt:SigningKey" "replace-with-a-random-secret-at-least-32-characters" --project backend/BridgePdx.Api
dotnet user-secrets set "DevelopmentAdministrator:Email" "your-development-admin@example.invalid" --project backend/BridgePdx.Api
dotnet user-secrets set "DevelopmentAdministrator:Password" "replace-with-a-unique-strong-development-password" --project backend/BridgePdx.Api
```

Equivalent environment-variable names are:

```text
Jwt__SigningKey
DevelopmentAdministrator__Email
DevelopmentAdministrator__Password
```

`Jwt:Issuer` and `Jwt:Audience` have non-secret application identifiers in `appsettings.json`; override them through `Jwt__Issuer` and `Jwt__Audience` when deployment architecture requires different values. Tokens expire after 15 minutes by default, configurable with `Jwt__LifetimeMinutes` up to the application-enforced 60-minute maximum.

In Development, startup creates the `Administrator` role and one administrator only when both bootstrap values are explicitly supplied. It never logs the password, never overwrites an existing account, and never runs the bootstrap in Production. If both bootstrap credentials are absent, startup safely creates no account. Supplying only one is treated as configuration error. The signing key remains mandatory in every non-test environment.

## Restore tools and apply migrations

From the repository root:

```sh
dotnet tool restore --tool-manifest backend/dotnet-tools.json
cd backend
dotnet tool run dotnet-ef -- \
  database update \
  --project BridgePdx.Api/BridgePdx.Api.csproj \
  --startup-project BridgePdx.Api/BridgePdx.Api.csproj
cd ..
```

The API also applies pending migrations and inserts clearly fictional seed resources when it starts in Development. The seeder is idempotent and is not run in production or tests.

## Complete local development workflow

1. Start Docker Desktop or another Compose-compatible runtime.
2. Start PostgreSQL from the repository root:

   ```sh
   docker compose -f backend/compose.yaml up -d postgres
   docker compose -f backend/compose.yaml ps
   ```

3. Restore the local EF tool and apply migrations if needed:

   ```sh
   dotnet tool restore --tool-manifest backend/dotnet-tools.json
   cd backend
   dotnet tool run dotnet-ef -- \
     database update \
     --project BridgePdx.Api/BridgePdx.Api.csproj \
     --startup-project BridgePdx.Api/BridgePdx.Api.csproj
   cd ..
   ```

4. Start the API with its stable Development launch profile:

   ```sh
   dotnet run --project backend/BridgePdx.Api/BridgePdx.Api.csproj --launch-profile development
   ```

   The server binds to `0.0.0.0:5080` so an Android emulator can reach it. Use these client URLs:

   - Host browser and iOS simulator/macOS: `http://127.0.0.1:5080`
   - Android emulator: `http://10.0.2.2:5080`
   - Swagger from the host: `http://127.0.0.1:5080/swagger`

5. Start an Android emulator.
6. Run Flutter:

   ```sh
   flutter pub get
   flutter run
   ```

The Android default is `http://10.0.2.2:5080`; iOS simulator and macOS default to `http://127.0.0.1:5080`. Override any development base URL with:

```sh
flutter run --dart-define=BRIDGE_PDX_API_BASE_URL=http://127.0.0.1:5080
```

A physical phone cannot use the Mac's loopback address. Put the phone and Mac on the same trusted development network, allow the API through the Mac firewall, determine the Mac's LAN address, and run for example:

```sh
flutter run --dart-define=BRIDGE_PDX_API_BASE_URL=http://192.168.1.25:5080
```

Android cleartext HTTP is allowed only by the debug manifest. Release builds do not opt into cleartext traffic; a future production API URL must use HTTPS. The API skips HTTPS redirection only in Development and Testing, while non-development hosting retains HTTPS redirection and remains configurable through standard ASP.NET Core settings.

## Run the API and Swagger

```sh
dotnet run --project backend/BridgePdx.Api/BridgePdx.Api.csproj --launch-profile development
```

Open `http://127.0.0.1:5080/swagger`. The development CORS allowlist is limited to the explicit localhost origins in `appsettings.Development.json`; no unrestricted production CORS policy is registered.

Available routes:

- `GET /health`
- `GET /api/resources`
- `GET /api/resources/{id}`
- `POST /api/resources/{resourceId}/reports`

Public routes do not require an account. Administrator routes require a valid bearer token with the `Administrator` role:

- `POST /api/admin/auth/login` — anonymous credential exchange with generic failure responses
- `GET /api/admin/auth/me` — safe administrator ID and email
- `GET /api/admin/reports` — paginated report review queue
- `GET /api/admin/reports/{id}` — report details
- `PATCH /api/admin/reports/{id}/status` — reviewed, resolved, or dismissed workflow updates

The report collection accepts `page`, `pageSize` (maximum 100), `status`, `reason`, `resourceId`, `submittedFromUtc`, and `submittedToUtc`. Results are newest-first and include safe resource context. Allowed transitions are `pending → reviewed`, `pending → dismissed`, `reviewed → resolved`, and `reviewed → dismissed`. Updates record the administrator ID and UTC review time. Reports cannot be deleted.

Login example:

```http
POST /api/admin/auth/login
Content-Type: application/json

{
  "email": "your-development-admin@example.invalid",
  "password": "your-locally-configured-password"
}
```

Use the returned token only in the authorization header:

```http
Authorization: Bearer your-short-lived-access-token
```

Do not put tokens in URLs. Login is protected by fixed-window rate limiting and Identity locks known accounts after five failed attempts for 15 minutes. Unknown accounts and incorrect passwords receive the same generic response.

The collection route accepts combinable `category`, `zipCode`, `openNow`, and `wheelchairAccessible` query parameters. Resource routes return active listings only.

### Anonymous outdated-information reports

The Flutter resource-detail screen submits reports through its own injected repository. The form asks for a reason and optional details only; it does not ask for a name, email address, phone number, account, or other identity field. Server responses likewise contain only report workflow data. As with any web request, infrastructure outside this application may still produce operational network logs, so the UI does not promise absolute anonymity.

Submit a report with:

```http
POST /api/resources/{resourceId}/reports
Content-Type: application/json

{
  "reason": "incorrect_hours",
  "details": "The posted weekday hours appear to have changed."
}
```

Supported stable reason codes are `incorrect_hours`, `incorrect_address`, `incorrect_phone_or_website`, `service_no_longer_available`, `eligibility_incorrect`, `accessibility_incorrect`, and `other`. Details are trimmed, whitespace-only details become `null`, and non-null details are limited to 500 characters. Missing or unsupported reasons and overlong details return the standard ASP.NET Core `400` validation response. Unknown or inactive resources return `404`; repeated submissions for the same resource and client can return `429`.

A successful request returns `201 Created` with the report ID, resource ID, reason, normalized details, UTC submission time, and `pending` review status. There is deliberately no public report-listing endpoint and no create/edit/delete resource or administration endpoint.

Submission rate limiting uses ASP.NET Core's fixed-window limiter and applies only to the report endpoint. Defaults are 10 submissions per client/resource pair per 60 seconds. Override `RateLimiting__ReportSubmission__PermitLimit` and `RateLimiting__ReportSubmission__WindowSeconds` through environment configuration when needed; use deployment-appropriate values rather than disabling the policy.

The `AddResourceReports` migration creates the report table, restrictive resource foreign key, and resource/status/submission-date indexes. `AddAdministratorIdentityAndReportReview` adds the Identity schema plus nullable reviewer ID and UTC review timestamp without replacing existing resources or reports. Apply all pending migrations with the migration command above.

### Swagger administrator authorization

In Development, open `http://127.0.0.1:5080/swagger`, call the login endpoint, select **Authorize**, and enter the returned bearer token. Swagger contains no bootstrap password or signing key. Public and `/api/admin/...` routes are visibly separated by their route/controller labels.

### Authentication security boundaries

This foundation provides password hashing, lockout, signed short-lived access tokens, server-side role authorization, and narrowly scoped response models. It does not yet provide refresh tokens, password reset, email verification, MFA, key rotation automation, token revocation, audit-log administration, or an administrator UI. Infrastructure may retain normal request metadata even though anonymous reports contain no reporter identity. The Flutter administrator interface is the next milestone; no administrator credential or token is stored in Flutter source.

## Run tests and checks

Backend tests do not use the developer's PostgreSQL instance, Docker, the network, or the real clock:

```sh
dotnet build backend/BridgePdx.Backend.sln
dotnet test backend/BridgePdx.Backend.sln
flutter analyze
flutter test
```
