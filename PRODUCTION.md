# Production

Building, shipping and deploying Ride Journal. For local development see
[DEVELOPMENT.md](DEVELOPMENT.md).

## Configuration

### App — `app/.env.prod`

`app/.env.prod` is **gitignored and intentionally not committed**. `scripts/setup.sh`
creates it from `app/.env.example`, which means a fresh checkout starts with the
*development* values — edit it before building anything for production:

```bash
API_BASE_URL=https://ride.kozjek.dev
GOOGLE_CLIENT_ID=1234567890-xxxxxxxxxxxx.apps.googleusercontent.com
```

These values are baked into the binary at build time via `--dart-define-from-file`;
there is no runtime configuration fetch. Changing them requires a rebuild.

> `Dockerfile.prod` reads `app/.env.prod` from the build context, so the file must
> exist on the build machine. `.dockerignore` excludes `app/.env` (dev) but keeps
> `app/.env.prod`.

### Backend — environment variables

The production container is configured entirely through environment variables
(`__` denotes nesting):

| Variable | Example | Notes |
| -------- | ------- | ----- |
| `ASPNETCORE_ENVIRONMENT` | `Production` | Disables Swagger |
| `MongoDb__ConnectionString` | `mongodb://mongodb:27017` | |
| `MongoDb__DatabaseName` | `ride_journal` | |
| `Jwt__Secret` | *(32+ chars)* | **Must be changed** — `appsettings.json` ships a placeholder |
| `Jwt__Issuer` | `RideJournal` | |
| `Jwt__Audience` | `RideJournalApp` | |
| `GoogleAuth__ClientId` | `…apps.googleusercontent.com` | Must equal the app's `GOOGLE_CLIENT_ID` |

[backend-api/docker-compose.prod.yml](backend-api/docker-compose.prod.yml) supplies
`Jwt__Secret` and `GoogleAuth__ClientId` from `${JWT_SECRET}` and
`${GOOGLE_CLIENT_ID}`, which Compose reads from `backend-api/.env` — created by
`scripts/setup.sh` from `backend-api/.env.example`. Fill both in before deploying.

## Docker images

Two images are defined at the repo root. **Both build with the repository root as
the build context**, because they need `app/` and `backend-api/` together.

| File | Contents | Use |
| ---- | -------- | --- |
| [Dockerfile](Dockerfile) | .NET API only | Deployments that host the web app elsewhere |
| [Dockerfile.prod](Dockerfile.prod) | Flutter web bundle + API | The full product: SPA at `/`, API under `/api/*` |

`Dockerfile.prod` builds the web bundle with
`flutter build web --release --dart-define-from-file=.env.prod`, then copies it into
the API's `wwwroot`. The API serves it with an SPA fallback that still returns a real
404 for unknown `/api/*` routes. Both images expose port `8080`.

## Build and publish

Single-architecture build:

```bash
docker build \
  -f Dockerfile.prod \
  -t nejek16/ridejournal:0.0.1 \
  -t nejek16/ridejournal:latest \
  .
```

Multi-architecture build, pushed directly to the registry:

```bash
docker buildx build \
  -f Dockerfile.prod \
  -t nejek16/ridejournal:0.0.1 \
  -t nejek16/ridejournal:latest \
  --platform linux/amd64,linux/arm64 \
  --push \
  .
```

Pushing a locally built image:

```bash
docker push nejek16/ridejournal:0.0.1
docker push nejek16/ridejournal:latest
```

## Deploy

```bash
cd backend-api
docker compose -f docker-compose.prod.yml up -d
```

Brings up MongoDB 7 and the combined image, with the UI and API on
`http://localhost:8080`. Indexes are created automatically at API startup.

If you are deploying against a database that predates the `ServerUpdatedAt` field,
run the one-off backfill first — see
[backend-api/README.md → Migrating an existing database](backend-api/README.md#migrating-an-existing-database).

## Android release

Set `API_BASE_URL` and `GOOGLE_CLIENT_ID` in `app/.env.prod` first, then from `app/`:

```bash
# APK (universal) — sideloading and direct distribution
flutter build apk --release --dart-define-from-file=.env.prod
# → build/app/outputs/flutter-apk/app-release.apk

# App Bundle — required for the Play Store
flutter build appbundle --release --dart-define-from-file=.env.prod
# → build/app/outputs/bundle/release/app-release.aab
```

> **Signing is not configured.** `android/app/build.gradle.kts` currently assigns the
> *debug* signing config to the release build type, so these artifacts are signed with
> the debug key and cannot be published. Create a keystore, reference it from a
> `key.properties` file and wire up a real `signingConfigs.release` before shipping —
> see the [Flutter Android deployment docs](https://docs.flutter.dev/deployment/android).
> Remember to register the release keystore's SHA-1 with the Android OAuth client
> (below), or Google Sign-In will fail in release builds only.

## iOS release

```bash
flutter build ios --release --dart-define-from-file=.env.prod
open ios/Runner.xcworkspace
```

In Xcode: **Product → Archive**, then distribute via App Store Connect or export an IPA.

Requires an Apple Developer account and a valid provisioning profile; configure
signing under *Signing & Capabilities*. See the
[Flutter iOS deployment docs](https://docs.flutter.dev/deployment/ios).

## Web / PWA

The web build is produced and served by `Dockerfile.prod` — there is nothing separate
to deploy. Note that a PWA **cannot** track a ride with the screen off; the
constraints and the wake-lock mitigation are documented in
[app/README.md → Web / PWA](app/README.md#web--pwa).

## Google OAuth setup

Google Sign-In needs OAuth client IDs from the Google Cloud Console. The same setup
applies to development and production — only the SHA-1 fingerprint differs.

### 1. Create the client IDs

1. Open the [Google Cloud Console](https://console.cloud.google.com/) and select or
   create a project.
2. Configure **APIs & Services → OAuth consent screen** (External, app name, support
   email). Add yourself as a test user while the app is in *Testing* mode.
3. Under **APIs & Services → Credentials → Create Credentials → OAuth client ID**,
   create three clients:

   | Type | Required input | Used for |
   | ---- | -------------- | -------- |
   | **Android** | Package name `dev.kozjek.ride` + SHA-1 of the signing key | Android native sign-in |
   | **iOS** | iOS bundle identifier `dev.kozjek.ride` | iOS native sign-in |
   | **Web application** | *(no extra config)* | `serverClientId` — the audience the backend verifies |

   Get a keystore's SHA-1 with `keytool`. For debug builds:

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android | grep SHA1
   ```

   For release builds, run the same command against your release keystore and add
   that SHA-1 to the Android client as well.

### 2. Configure the app

Put the **Web application** client ID in `app/.env` (development) and
`app/.env.prod` (release):

```bash
GOOGLE_CLIENT_ID=1234567890-xxxxxxxxxxxx.apps.googleusercontent.com
```

It is read by [app/lib/core/config/env_config.dart](app/lib/core/config/env_config.dart)
and passed to `GoogleSignIn` in
[app/lib/data/repositories/auth_repository_impl.dart](app/lib/data/repositories/auth_repository_impl.dart).

### 3. Configure the backend

Set the **same** client ID so the `aud` check passes — via `GoogleAuth__ClientId` in
production, or `appsettings.Development.json` locally:

```json
"GoogleAuth": {
  "ClientId": "1234567890-xxxxxxxxxxxx.apps.googleusercontent.com"
}
```

> **Important:** this value must equal the `aud` claim Google puts on the ID tokens the
> app sends. If the app passes `serverClientId` to `GoogleSignIn`, use the Web client
> ID. If it only passes `clientId` (iOS), use the iOS client ID. A mismatch rejects
> every Google login.

### 4. Platform specifics

**Android** — no code change; the Android OAuth client is matched by package name
plus SHA-1.

**iOS** — add the iOS OAuth client's *reversed* client ID as a URL scheme in
`app/ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Reversed iOS client ID, e.g. com.googleusercontent.apps.1234567890-xxxxx -->
      <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Without it, Google's sign-in sheet cannot return to the app on iOS. This entry is
**not present today**.

## Continuous integration

[.github/workflows/backend-ci.yml](.github/workflows/backend-ci.yml) runs on every
push and pull request that touches `backend-api/**`. It starts a `mongo:7` service,
then runs `dotnet restore`, `dotnet build --configuration Release` and `dotnet test`
against the `ride_journal_test` database with a throwaway JWT secret.

The path filter means **the Flutter app has no CI** — `flutter analyze` and
`flutter test` are developer-run only. There is no automated image build or deploy;
the Docker steps above are manual.
