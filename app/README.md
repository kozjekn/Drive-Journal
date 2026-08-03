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

| Variable           | Description            | Default                 |
| ------------------ | ---------------------- | ----------------------- |
| `API_BASE_URL`     | Backend API base URL   | `http://localhost:5000` |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | _(empty)_               |

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
   | **Android** | Package name (`com.drivejournal.drive_journal`) + SHA-1 of your signing key | Android native sign-in |
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

### Android

- Location permissions (fine, coarse, background) in `AndroidManifest.xml`
- Foreground service permission for background GPS tracking

### iOS

- `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` in `Info.plist`
- `UIBackgroundModes: location` for background tracking

## TODOs / Future Work

- **Elevation accuracy** — GPS altitude is unreliable; integrate barometer or elevation API
- **Ride export** — GPX/KML export
- **User settings** — units (km/mi), map style, recording interval
- **Push notifications** — notify when followed users post new rides
- **Ride photos** — attach photos to rides
- **Offline queue** — queue failed API calls for retry when connectivity returns
