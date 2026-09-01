#!/usr/bin/env bash
#
# One-time development setup for the Ride Journal repo.
#
# Creates the local environment files from their committed .example templates and
# restores dependencies for both halves of the project. Safe to re-run: an existing
# file is never overwritten.
#
# It deliberately does NOT start MongoDB — see DEVELOPMENT.md for that.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
skip() { printf '  \033[90m•\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

# copy_env <template> <destination>
copy_env() {
  local template="$1" dest="$2"
  if [ ! -f "$template" ]; then
    warn "missing template $template — skipped $dest"
    return
  fi
  if [ -f "$dest" ]; then
    skip "$dest already exists, left untouched"
  else
    cp "$template" "$dest"
    ok "created $dest"
  fi
}

bold "Environment files"
copy_env app/.env.example         app/.env
copy_env app/.env.example         app/.env.prod
copy_env backend-api/.env.example backend-api/.env

bold "Dependencies"
if command -v flutter >/dev/null 2>&1; then
  (cd app && flutter pub get >/dev/null)
  ok "flutter pub get"
else
  warn "flutter not found on PATH — skipped 'flutter pub get' (install the Flutter SDK)"
fi

if command -v dotnet >/dev/null 2>&1; then
  (cd backend-api && dotnet restore >/dev/null)
  ok "dotnet restore"
else
  warn "dotnet not found on PATH — skipped 'dotnet restore' (install the .NET 9 SDK)"
fi

cat <<'EOF'

Setup complete.

Before you build for production, edit app/.env.prod — it was seeded from the dev
template and still points API_BASE_URL at http://localhost:5000.

Next steps:
  1. cd backend-api && docker compose up -d          # start MongoDB
  2. dotnet run --project src/RideJournal.API        # API on http://localhost:5000
  3. cd ../app && flutter run --dart-define-from-file=.env

See DEVELOPMENT.md for the full guide.
EOF
