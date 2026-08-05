# Ride Journal

A motorcycle ride tracker app for iOS and Android. Records GPS-tracked rides, stores them locally, syncs with a .NET 9 backend, and displays them with detailed stats and map views.

## Features

- **Record rides** with real-time GPS tracking (including background)
- **View ride history** in a feed with distance, duration, and speed
- **Ride details** with route on map, elevation, avg/max speed, timestamps
- **Offline-first** — works without internet (map tiles require connectivity)
- **Swipe to delete** rides from the list
- **Authentication** — email/password registration & login, Google Sign-In
- **Ride sync** — automatic sync with backend using updatedAt/syncedAt timestamps
- **Social feed** — follow other riders and see their public rides
- **User search** — find and follow riders by name or email
- **User profiles** — view follower/following counts and toggle follow

## Architecture

- **Clean Architecture** — domain, data, and presentation layers
- **State Management** — Provider (ChangeNotifier)
- **Dependency Injection** — get_it + injectable
- **Local Storage** — Hive (NoSQL key-value store)
- **Remote API** — Dio HTTP client with JWT auth interceptor and auto token refresh
- **Secure Storage** — flutter_secure_storage for tokens
- **Maps** — OpenStreetMap via flutter_map
- **GPS** — geolocator with background tracking (foreground service on Android, background modes on iOS)

## Project Structure

```
lib/
├── core/
│   ├── config/         # Environment configuration (compile-time --dart-define)
│   ├── error/          # Custom exceptions
│   ├── network/        # API client (Dio), API exceptions
│   ├── services/       # Location service
│   ├── theme/          # App theme
│   └── utils/          # Distance, speed, elevation calculators
├── data/
│   ├── datasources/
│   │   ├── local/      # Hive ride storage, secure auth storage
│   │   └── remote/     # Auth, rides, users API data sources
│   ├── models/         # Ride/RoutePoint models with Hive adapters + JSON serialization
│   └── repositories/   # Auth and ride repository implementations
├── di/                 # Dependency injection (get_it)
├── domain/
│   ├── entities/       # Ride, RoutePoint, User, AuthToken, UserProfile
│   ├── repositories/   # Abstract repository interfaces
│   └── usecases/       # GetAllRides, SaveRide, DeleteRide, etc.
├── presentation/
│   ├── pages/          # Auth (login, register), home, feed, search, profile, ride pages
│   ├── providers/      # Auth, feed, ride list, record ride, user search/profile providers
│   └── widgets/        # Reusable widgets (ride card, stat tile)
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Xcode (for iOS)
- Android Studio (for Android)

### Setup

```bash
cd app
cp .env.example .env        # then edit .env with your values
flutter pub get
```

### Environment Variables

Config is baked in at build time via `--dart-define-from-file` (read by
[lib/core/config/env_config.dart](lib/core/config/env_config.dart) with `String.fromEnvironment`).
Values live in `.env` for local dev and `.env.prod` for production builds.

| Variable           | Description            | Notes                                    |
| ------------------ | ---------------------- | ---------------------------------------- |
| `API_BASE_URL`     | Backend API base URL   | **No default** — an unset value fails loudly at startup rather than silently failing every request |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | _(empty)_                                |

The dev API listens on **port 5000** (`backend-api/.../launchSettings.json`).

| Target                     | File            | `API_BASE_URL`                    |
| -------------------------- | --------------- | --------------------------------- |
| Web / iOS simulator        | `.env`          | `http://localhost:5000`           |
| Android emulator           | `.env.android`  | `http://10.0.2.2:5000`            |
| Physical device on the LAN | `.env.device`   | `http://<your-machine-ip>:5000`   |
| Production                 | `.env.prod`     | `https://ride.kozjek.dev`         |

```bash
flutter run -d chrome         --dart-define-from-file=.env
flutter run -d emulator-5554  --dart-define-from-file=.env.android
```

Debug Android builds set `usesCleartextTraffic` so plain-HTTP dev endpoints work;
release builds are HTTPS-only.

### Run

```bash
flutter run --dart-define-from-file=.env
```

## Google Sign-In Setup

### 1. Create OAuth client IDs in Google Cloud Console

1. Open the [Google Cloud Console](https://console.cloud.google.com/) and select (or create) a project.
2. Configure **APIs & Services → OAuth consent screen** (External, app name, support email). Add yourself as a test user while the app is in *Testing* mode.
3. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID** and create:

   | Type | Required input | Used for |
   | ---- | -------------- | -------- |
   | **Android** | Package name (`dev.kozjek.ride`) + SHA-1 of your signing key | Android native sign-in |
   | **iOS** | iOS bundle identifier (see `ios/Runner.xcodeproj`) | iOS native sign-in |
   | **Web application** | (no extra config) | `serverClientId` — the audience the backend expects |

   Get the debug SHA-1 with:

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
   ```

   For release builds, run the same command against your release keystore and add that SHA-1 to the Android client too.

### 2. Configure the app

Put the **Web application** Client ID in `.env`:

```bash
GOOGLE_CLIENT_ID=1234567890-xxxxxxxxxxxx.apps.googleusercontent.com
```

This value is loaded by [lib/core/config/env_config.dart](lib/core/config/env_config.dart) and passed to `GoogleSignIn` in [lib/data/repositories/auth_repository_impl.dart](lib/data/repositories/auth_repository_impl.dart). The backend must use the **same** Client ID in its `GoogleAuth:ClientId` setting so the `aud` check passes.

### 3. Platform-specific config

**Android** — no code change needed; the Android OAuth client is matched by package name + SHA-1.

**iOS** — add the iOS OAuth client's reversed client ID as a URL scheme in `ios/Runner/Info.plist`:

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

Without this URL scheme, Google's sign-in sheet won't be able to return to the app on iOS.

### Test

```bash
flutter test
```

### Analyze

```bash
flutter analyze
```

### Format

```bash
dart format lib/ test/
```

## Debug Android (Emulator)

1. Open Android Studio and launch the AVD Manager (`Tools > Device Manager`)
2. Create or start an Android emulator (recommended: Pixel 7 API 34+)
3. Run:

```bash
flutter run -d android --dart-define-from-file=.env
```

To pick a specific emulator if multiple devices are connected:

```bash
flutter devices          # list available devices
flutter run -d <device-id> --dart-define-from-file=.env
```

**Hot reload** is available — press `r` in the terminal. Press `R` for hot restart.

## Debug iOS (Simulator)

1. Open Xcode and launch a simulator (`Xcode > Open Developer Tool > Simulator`), or from terminal:

```bash
open -a Simulator
```

2. Run:

```bash
flutter run -d ios --dart-define-from-file=.env
```

> **Note:** To run on a physical iOS device, you need an Apple Developer account and must configure signing in `ios/Runner.xcworkspace` under `Signing & Capabilities`.

**Hot reload** is available — press `r` in the terminal. Press `R` for hot restart.

## Build Production Android

### APK (universal)

```bash
flutter build apk --release --dart-define-from-file=.env.prod
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (recommended for Play Store)

```bash
flutter build appbundle --release --dart-define-from-file=.env.prod
```

Output: `build/app/outputs/bundle/release/app-release.aab`

> **Note:** For Play Store publishing, you need to configure signing in `android/app/build.gradle` with your keystore. See [Flutter Android deployment docs](https://docs.flutter.dev/deployment/android).

## Build Production iOS

```bash
flutter build ios --release --dart-define-from-file=.env.prod
```

Then open the Xcode workspace to archive and distribute:

```bash
open ios/Runner.xcworkspace
```

In Xcode: `Product > Archive`, then distribute via App Store Connect or export as IPA.

> **Note:** Requires an Apple Developer account and valid provisioning profile. Configure signing in `Signing & Capabilities` within Xcode. See [Flutter iOS deployment docs](https://docs.flutter.dev/deployment/ios).

## Platform Configuration

Application id / bundle id is `dev.kozjek.ride` on every platform.

### Android

- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`,
  `FOREGROUND_SERVICE_LOCATION`, `WAKE_LOCK`, `POST_NOTIFICATIONS`
- Screen-off tracking works via geolocator's `foregroundServiceType="location"`
  service, started while the app is visible. `ACCESS_BACKGROUND_LOCATION` is
  deliberately **not** declared: it isn't needed for this model, it triggers a
  Play Store policy review, and it makes Android 11+ silently discard the runtime
  location request.
- `WAKE_LOCK` is required — the foreground service acquires a `PARTIAL_WAKE_LOCK`
  and the plugin does not declare the permission itself.
- The foreground-service notification is always silent and minimized; geolocator
  hardcodes `IMPORTANCE_NONE` on its channel.

### iOS

- `NSLocationWhenInUseUsageDescription` plus `UIBackgroundModes: location`. "When
  In Use" is sufficient for screen-locked tracking started in the foreground;
  "Always" is not needed, so the `NSLocationAlways*` keys are not declared.

### Web / PWA

**A PWA cannot track with the screen off.** No browser API can read GPS while the
document is hidden: service workers have no `navigator.geolocation` at all, and
Background Sync / Periodic Background Sync are Chromium-only, absent from Safari,
and run in the worker regardless. The app holds a Screen Wake Lock while recording
and says so in the UI; that is the entire mitigation.

- Geolocation and Screen Wake Lock both require a **secure context**.
  `http://localhost` qualifies; a LAN IP over plain HTTP does not.
- On an **installed iOS PWA below iOS 18.4** the wake lock is a silent no-op
  (Apple bug). The recording UI reports the verified lock state, so it says
  "Can't keep your screen awake on this device" rather than claiming success.

### Process kill

Neither native platform survives a process kill (swipe-away, OS/OEM kill). An
in-progress recording is flushed to a separate append-only Hive box every 10
points / 15 seconds and on every backgrounding, so a kill costs seconds rather
than the whole ride; the ride list then offers Resume / Save as-is / Discard.

## TODOs / Future Work

- **Elevation accuracy** — GPS altitude is unreliable; integrate barometer or elevation API
- **Ride export** — GPX/KML export
- **User settings** — units (km/mi), map style, recording interval
- **Push notifications** — notify when followed users post new rides
- **Ride photos** — attach photos to rides
- **Kill-proof tracking** — surviving a process kill needs a second FlutterEngine
  in a standalone service (`flutter_background_geolocation` or hand-rolled)
- **Connectivity-triggered sync** — sync currently retries on app resume, save,
  and pull-to-refresh; a `connectivity_plus` listener would retry the moment the
  network returns
- **Ride list payload** — `GET /api/rides` returns every ride with all route
  points inline and has no pagination
