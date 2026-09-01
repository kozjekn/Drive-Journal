# Ride Journal — App

Flutter client for the Ride Journal motorcycle ride tracker. Records GPS-tracked
rides, stores them locally in Hive, syncs with the .NET 9 backend, and displays them
with detailed stats and map views.

> Setup, running and debugging: [DEVELOPMENT.md](../DEVELOPMENT.md).
> Release builds: [PRODUCTION.md](../PRODUCTION.md).

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
