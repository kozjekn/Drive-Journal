<div align="center">

<img src="app/assets/logo_full.png" alt="Ride Journal" width="360">

**A motorcycle ride tracker for Android, iOS and the web.**

</div>

---

Ride Journal records GPS-tracked rides — including while the screen is off — stores
them on the device first, syncs them to a .NET backend when a network is available,
and shows them back with route maps, stats and a social feed of the riders you follow.

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

## Tech stack

| Layer | Stack |
| ----- | ----- |
| App | Flutter (Dart 3.11) — Android, iOS, and an installable web PWA |
| API | ASP.NET Core .NET 9, Clean Architecture, MediatR CQRS |
| Database | MongoDB 7 |
| Maps | OpenStreetMap via `flutter_map` |
| Auth | JWT access/refresh tokens, BCrypt, Google Sign-In |

## Repository layout

| Path | Contents |
| ---- | -------- |
| [app/](app/) | Flutter client — see [app/README.md](app/README.md) |
| [backend-api/](backend-api/) | .NET 9 REST API — see [backend-api/README.md](backend-api/README.md) |
| [scripts/setup.sh](scripts/setup.sh) | One-time development setup |
| [Dockerfile](Dockerfile) | API-only production image |
| [Dockerfile.prod](Dockerfile.prod) | Combined image — Flutter web bundle served by the API |
| [.github/workflows/](.github/workflows/) | Backend CI |

## Quick start

```bash
./scripts/setup.sh                                  # env files + dependencies

cd backend-api
docker compose up -d                                # MongoDB on :27017
dotnet run --project src/RideJournal.API            # API on :5000

cd ../app
flutter run --dart-define-from-file=.env
```

Full instructions — prerequisites, per-platform configuration, debugging and tests —
are in [DEVELOPMENT.md](DEVELOPMENT.md).

## Documentation

| Document | Covers |
| -------- | ------ |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Prerequisites, setup, local configuration, running, debugging, testing |
| [PRODUCTION.md](PRODUCTION.md) | Docker images, deployment, Android/iOS release builds, Google OAuth, CI |
| [app/README.md](app/README.md) | Flutter architecture, project structure, platform configuration, roadmap |
| [backend-api/README.md](backend-api/README.md) | API architecture, the ride sync contract, database notes |
