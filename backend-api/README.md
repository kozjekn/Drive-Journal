# Ride Journal — Backend API

C# .NET 9 REST API for the Ride Journal motorcycle ride tracker. Provides
authentication, ride CRUD, sync, user profiles, and social features over MongoDB.

> Setup, running and debugging: [DEVELOPMENT.md](../DEVELOPMENT.md).
> Docker images and deployment: [PRODUCTION.md](../PRODUCTION.md).
> Endpoints are documented by Swagger UI at `/swagger` when running in Development.

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

`Program.cs` wires the layers together, creates MongoDB indexes at startup, and
serves the bundled Flutter web app from `wwwroot` with an SPA fallback that still
returns a real 404 for unknown `/api/*` routes.

## Ride sync

Clients are offline-first: a ride is written locally, then pushed. `POST /api/rides/sync`
is the single push/pull path.

**Request** — `{ "lastSyncAt": DateTime?, "rides": RideDto[] }`
**Response** — `{ "syncedAt": DateTime, "updatedRides": RideDto[], "deletedRideIds": string[], "hasMore": bool }`

Two timestamps, deliberately distinct:

- **`updatedAt`** is the _client's_ logical version. Conflicts resolve to the later
  `updatedAt`. Clients send UTC (`...Z`).
- **`serverUpdatedAt`** is stamped by the repository on every write and is the pull
  cursor. Filtering the pull on `updatedAt` would drop rides whenever a device's
  clock disagreed with the server's.

`syncedAt` is what the client sends back as `lastSyncAt`. When a pull is truncated
(`hasMore: true`, batch size 50) it is the **last returned ride's**
`serverUpdatedAt`, not "now", so paging cannot skip a ride written mid-sequence.

Other contract guarantees:

- `POST /api/rides` is **idempotent** — replaying a client-generated id you own
  returns `200` with the stored ride. A duplicate id owned by someone else is `409`.
- `DELETE /api/rides/{id}` **soft-deletes** (sets `deletedAt`) so the deletion can
  reach other devices via `deletedRideIds`, and is idempotent (`204` when already
  deleted). Every read filters tombstones out.
- A stale client cannot resurrect a deleted ride: a push whose `updatedAt` predates
  the deletion is ignored.
- Request caps: 50 rides per sync, 200k route points per ride, 64 MB body.

## Database

Databases by environment: `ride_journal_dev` (local), `ride_journal_test` (CI),
`ride_journal` (production). Indexes are created on API startup; there is no
migration framework.

> Field names in MongoDB are **PascalCase** — no camelCase element convention is
> registered, so the driver uses the C# property names verbatim (`UserId`, `StartTime`,
> `RoutePoints`, …). Only `_id` is remapped. The JSON API is camelCase; the database
> is not. A camelCase query silently matches nothing.

### Migrating an existing database

`ServerUpdatedAt` is new, so backfill it once or pre-existing rides will never be
pulled by a client:

```bash
mongosh "mongodb://localhost:27017/ride_journal_dev" --eval '
  db.rides.updateMany({ServerUpdatedAt: {$exists: false}},
                      [{$set: {ServerUpdatedAt: "$UpdatedAt"}}])'
```
