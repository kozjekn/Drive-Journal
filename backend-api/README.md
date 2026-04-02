# DriveJournal Backend API

C# .NET 9 REST API for the DriveJournal motorcycle ride tracker. Provides authentication, ride CRUD, sync, user profiles, and social features.

## Prerequisites

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Docker](https://www.docker.com/get-started) (for MongoDB)
- A code editor (VS Code recommended)

## Quick Start

### 1. Start MongoDB

```bash
docker compose up -d
```

This starts a local MongoDB instance on port `27017`.

### 2. Run the API

```bash
dotnet run --project src/DriveJournal.API
```

The API starts at `http://localhost:5000` by default (configured in launch profile).

### 3. Open Swagger UI

Navigate to `http://localhost:5000/swagger` to explore and test the API.

## Development

### Build

```bash
dotnet build
```

### Run with hot reload

```bash
dotnet watch run --project src/DriveJournal.API
```

### Run tests

```bash
dotnet test
```

### VS Code

Open the `backend-api` folder in VS Code. Pre-configured debug launch configs are in `.vscode/`:

- **Launch API (Development)** — build and run with debugger attached
- **Attach to API** — attach to a running API process

Use `Ctrl+Shift+B` / `Cmd+Shift+B` to run the default build task.

## Configuration

Configuration is in `src/DriveJournal.API/appsettings.json` and overridden by `appsettings.Development.json` locally.

Key settings:

| Section | Key | Description |
|---------|-----|-------------|
| `MongoDb` | `ConnectionString` | MongoDB connection string |
| `MongoDb` | `DatabaseName` | Database name |
| `Jwt` | `Secret` | JWT signing key (min 32 chars) |
| `Jwt` | `Issuer` / `Audience` | Token issuer and audience |
| `GoogleAuth` | `ClientId` | Google OAuth client ID |

For production, override via environment variables (double underscore notation):

```bash
export MongoDb__ConnectionString="mongodb://prod-host:27017"
export Jwt__Secret="your-production-secret-key-here!!"
```

## Docker (Production)

### Build and run full stack

```bash
JWT_SECRET="your-secret" GOOGLE_CLIENT_ID="your-id" docker compose -f docker-compose.prod.yml up --build
```

This starts both the API (port `5000`) and MongoDB.

## Architecture

```
src/
├── DriveJournal.Domain         # Entities, enums, repository interfaces
├── DriveJournal.Application    # CQRS (MediatR), DTOs, validators, mapping
├── DriveJournal.Infrastructure # MongoDB repos, JWT, BCrypt, Google auth
└── DriveJournal.API            # Controllers, middleware, Swagger, DI setup

tests/
└── DriveJournal.Tests          # Unit + integration tests
```

## API Endpoints

### Auth
- `POST /api/auth/register` — Register with email/password
- `POST /api/auth/login` — Login with email/password
- `POST /api/auth/google` — Login/register with Google ID token
- `POST /api/auth/refresh` — Refresh access token

### Rides (requires auth)
- `GET /api/rides` — Get my rides
- `GET /api/rides/{id}` — Get ride by ID
- `POST /api/rides` — Create ride
- `PUT /api/rides/{id}` — Update ride
- `DELETE /api/rides/{id}` — Delete ride
- `POST /api/rides/sync` — Sync rides between device and server
- `GET /api/rides/feed` — Get followed users' rides
- `GET /api/rides/public/{id}` — Get public ride (no auth required)

### Users (requires auth)
- `GET /api/users/me` — Get my profile
- `PUT /api/users/me` — Update my profile
- `POST /api/users/me/profile-picture` — Upload profile picture
- `GET /api/users/search?q=` — Search users
- `GET /api/users/{id}` — Get user profile
- `POST /api/users/{id}/follow` — Follow user
- `DELETE /api/users/{id}/follow` — Unfollow user
- `GET /api/users/{id}/followers` — Get followers
- `GET /api/users/{id}/following` — Get following
