# Drive Journal

A motorcycle ride tracker app for iOS and Android. Records GPS-tracked rides, stores them locally, and displays them with detailed stats and map views.

## Features

- **Record rides** with real-time GPS tracking (including background)
- **View ride history** in a feed with distance, duration, and speed
- **Ride details** with route on map, elevation, avg/max speed, timestamps
- **Offline-first** — works without internet (map tiles require connectivity)
- **Swipe to delete** rides from the list

## Architecture

- **Clean Architecture** — domain, data, and presentation layers
- **State Management** — Provider (ChangeNotifier)
- **Dependency Injection** — get_it + injectable
- **Local Storage** — Hive (NoSQL key-value store)
- **Maps** — OpenStreetMap via flutter_map
- **GPS** — geolocator with background tracking (foreground service on Android, background modes on iOS)

## Project Structure

```
lib/
├── core/           # Errors, theme, utilities (distance/speed/elevation calculators)
├── data/           # Models, data sources (local Hive + remote stub), repository impl
├── di/             # Dependency injection setup
├── domain/         # Entities, repository interfaces, use cases
├── presentation/   # Providers, pages, widgets
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
flutter pub get
```

### Run

```bash
flutter run
```

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
flutter run -d android
```

To pick a specific emulator if multiple devices are connected:

```bash
flutter devices          # list available devices
flutter run -d <device-id>
```

**Hot reload** is available — press `r` in the terminal. Press `R` for hot restart.

## Debug iOS (Simulator)

1. Open Xcode and launch a simulator (`Xcode > Open Developer Tool > Simulator`), or from terminal:

```bash
open -a Simulator
```

2. Run:

```bash
flutter run -d ios
```

> **Note:** To run on a physical iOS device, you need an Apple Developer account and must configure signing in `ios/Runner.xcworkspace` under `Signing & Capabilities`.

**Hot reload** is available — press `r` in the terminal. Press `R` for hot restart.

## Build Production Android

### APK (universal)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (recommended for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

> **Note:** For Play Store publishing, you need to configure signing in `android/app/build.gradle` with your keystore. See [Flutter Android deployment docs](https://docs.flutter.dev/deployment/android).

## Build Production iOS

```bash
flutter build ios --release
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

- **Backend sync** — remote data source is stubbed, ready for API integration
- **Elevation accuracy** — GPS altitude is unreliable; integrate barometer or elevation API
- **Ride export** — GPX/KML export
- **User settings** — units (km/mi), map style, recording interval
