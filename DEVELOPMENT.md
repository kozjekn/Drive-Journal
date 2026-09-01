# Development

How to set up, run and debug Ride Journal locally. For release builds and
deployment see [PRODUCTION.md](PRODUCTION.md).

## Prerequisites

| Tool | Needed for |
| ---- | ---------- |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable, Dart ≥ 3.11) | The app |
| [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0) | The API |
| [Docker](https://www.docker.com/get-started) | MongoDB |
| Xcode | iOS builds and the simulator |
| Android Studio | Android builds and the emulator |

## First-time setup

```bash
./scripts/setup.sh
```

The script is idempotent — existing files are never overwritten — and it:

- creates `app/.env` and `app/.env.prod` from `app/.env.example`
- creates `backend-api/.env` from `backend-api/.env.example`
- runs `flutter pub get` and `dotnet restore`

It does **not** start MongoDB, and it does **not** fill in any values. Edit
`app/.env` next (see below).

## Configuration

### App

App config is baked in at **build time** via `--dart-define-from-file`, read by
[app/lib/core/config/env_config.dart](app/lib/core/config/env_config.dart) with
`String.fromEnvironment`. Changing a value requires a rebuild, not a restart.
`app/.env` is used for development, `app/.env.prod` for release builds. Both are
gitignored; only `app/.env.example` is committed.

| Variable | Description | Notes |
| -------- | ----------- | ----- |
| `API_BASE_URL` | Backend API base URL | **No default** — an unset value fails loudly at startup rather than silently failing every request |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | Optional; leave empty to disable Google Sign-In. See [PRODUCTION.md → Google OAuth setup](PRODUCTION.md#google-oauth-setup) |

The dev API listens on **port 5000**, so set `API_BASE_URL` in `app/.env` to match
your run target:

| Target | `API_BASE_URL` |
| ------ | -------------- |
| Web / iOS simulator | `http://localhost:5000` |
| Android emulator | `http://10.0.2.2:5000` |
| Physical device on your LAN | `http://<your-machine-ip>:5000` |

Debug Android builds set `usesCleartextTraffic` so plain-HTTP dev endpoints work;
release builds are HTTPS-only.

### Backend

Local settings live in
[backend-api/src/RideJournal.API/appsettings.Development.json](backend-api/src/RideJournal.API/appsettings.Development.json)
(database `ride_journal_dev`, `Urls` bound to `0.0.0.0:5000`). Any setting can be
overridden with an environment variable, using `__` for nesting:

```bash
export MongoDb__ConnectionString="mongodb://localhost:27017"
export Jwt__Secret="DevSecretKey_AtLeast32Characters_Long!!"
export GoogleAuth__ClientId="1234567890-xxxxxxxxxxxx.apps.googleusercontent.com"
```

`backend-api/.env` is only read by `docker-compose.prod.yml` — `dotnet run` ignores it.

## Running

### 1. MongoDB

```bash
cd backend-api
docker compose up -d
```

Starts MongoDB 7 on port `27017` with a named volume for persistence.

### 2. API

```bash
dotnet run --project src/RideJournal.API
```

The API listens on `http://0.0.0.0:5000` (see
`src/RideJournal.API/Properties/launchSettings.json`). It binds all interfaces so an
emulator or a phone on the same network can reach it.

Swagger UI — available in Development only — is at `http://localhost:5000/swagger`.

### 3. App

```bash
cd app
flutter run --dart-define-from-file=.env
```

## Debugging

### Android emulator

1. Open Android Studio and launch the AVD Manager (`Tools > Device Manager`).
2. Create or start an emulator (recommended: Pixel 7, API 34+).
3. Set `API_BASE_URL=http://10.0.2.2:5000` in `app/.env`, then:

```bash
flutter run -d android --dart-define-from-file=.env
```

To pick a specific device when several are connected:

```bash
flutter devices
flutter run -d <device-id> --dart-define-from-file=.env
```

### iOS simulator

1. Launch a simulator from Xcode (`Xcode > Open Developer Tool > Simulator`) or
   with `open -a Simulator`.
2. Run:

```bash
flutter run -d ios --dart-define-from-file=.env
```

> Running on a **physical** iOS device needs an Apple Developer account and signing
> configured in `ios/Runner.xcworkspace` under *Signing & Capabilities*.

**Hot reload** works in both: press `r` in the terminal, `R` for a hot restart.

### API hot reload

```bash
cd backend-api
dotnet watch run --project src/RideJournal.API
```

### VS Code

Both halves ship launch configurations.

- Open `app/` — [app/.vscode/launch.json](app/.vscode/launch.json) provides
  *Debug (iOS Simulator)*, *Debug (Android Emulator)*, *Debug (Chrome)*, *Profile*
  and *Release*. The debug configs pass `--dart-define-from-file=.env` for you.
- Open `backend-api/` — [backend-api/.vscode/launch.json](backend-api/.vscode/launch.json)
  provides *Launch API (Development)* (builds and attaches the debugger) and
  *Attach to API*. `Cmd+Shift+B` / `Ctrl+Shift+B` runs the default build task.

## Testing and quality

```bash
# App
cd app
flutter test
flutter analyze
dart format lib/ test/

# Backend
cd backend-api
dotnet build
dotnet test
```

## Known gaps

- **Android release signing is unconfigured.** `app/android/app/build.gradle.kts`
  still assigns the *debug* signing config to release builds. Fix before publishing —
  see [PRODUCTION.md → Android release](PRODUCTION.md#android-release).
- **iOS Google Sign-In will not return to the app.** `app/ios/Runner/Info.plist` has
  no `CFBundleURLTypes` entry for the reversed iOS client ID.
- **`GOOGLE_CLIENT_ID` is empty** in the templates and in `appsettings.json`, so
  Google Sign-In is inactive until configured.
- **There is no Flutter CI** — `flutter analyze` and `flutter test` only run locally.
  See [PRODUCTION.md → Continuous integration](PRODUCTION.md#continuous-integration).
