# RideJournal Backend API

C# .NET 9 REST API for the RideJournal motorcycle ride tracker. Provides authentication, ride CRUD, sync, user profiles, and social features.

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
dotnet run --project src/RideJournal.API
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
dotnet watch run --project src/RideJournal.API
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

## Architecture

```
src/
├── RideJournal.Domain         # Entities, enums, repository interfaces
├── RideJournal.Application    # CQRS (MediatR), DTOs, validators, mapping
├── RideJournal.Infrastructure # MongoDB repos, JWT, BCrypt, Google auth
└── RideJournal.API            # Controllers, middleware, Swagger, DI setup

tests/
└── RideJournal.Tests          # Unit + integration tests
```

## Production

Build the **combined image** (Flutter web bundle + API). Note the build context is the repo
root (`..`), not `backend-api/`, and it uses `Dockerfile.prod`:

Config is baked into the web bundle at build time from the committed `app/.env.prod` file via
`flutter build web --dart-define-from-file=.env.prod` (no runtime asset fetch). Edit
`app/.env.prod` to change `API_BASE_URL` / `GOOGLE_CLIENT_ID` before building.

```
docker build \
  -f ../Dockerfile.prod \
  -t nejek16/ridejournal:0.0.1 \
  -t nejek16/ridejournal:latest \
  .. 
```

Push to Docker Hub:
```
docker push "nejek16/ridejournal:0.0.1"
docker push "nejek16/ridejournal:latest"
```

### Creating the OAuth Client ID

1. Open the [Google Cloud Console](https://console.cloud.google.com/) and create a project (or pick an existing one).
2. Go to **APIs & Services → OAuth consent screen**, configure it (External, app name, support email), and add yourself as a test user while in *Testing* mode.
3. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
4. Create the client IDs needed by the mobile app (see the [app README](../app/README.md#google-sign-in-setup) for the platform-specific list):
   - **Android** OAuth client — needs the app's package name and the SHA-1 fingerprint of the signing key.
   - **iOS** OAuth client — needs the app's bundle identifier.
   - **Web application** OAuth client — used as the `serverClientId` so all platforms produce ID tokens with the same audience. Recommended for a unified backend check.
5. Copy the Client ID of whichever OAuth client the app uses as its `serverClientId` (the Web application client is the typical choice) into `appsettings.Development.json`:

   ```json
   "GoogleAuth": {
     "ClientId": "1234567890-xxxxxxxxxxxx.apps.googleusercontent.com"
   }
   ```

   Or via environment variable:

   ```bash
   export GoogleAuth__ClientId="1234567890-xxxxxxxxxxxx.apps.googleusercontent.com"
   ```

> **Important:** the value here must equal the `aud` claim that Google will put on the ID tokens the app sends. If the app passes `serverClientId` to `GoogleSignIn`, this should be that Web client ID. If the app only passes `clientId` (iOS), this should be the iOS client ID. Mismatch → backend rejects all Google logins.