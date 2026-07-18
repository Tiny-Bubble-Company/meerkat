#!/usr/bin/env bash
# Runs on the Hetzner server after GitHub Actions rsyncs the repo.
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/meerkat-apps/meerkat}"
cd "$APP_DIR"

if [ ! -f .env.production ]; then
  echo "ERROR: missing $APP_DIR/.env.production (needs POSTGRES_PASSWORD, RAILS_MASTER_KEY, ...)" >&2
  exit 1
fi

chmod +x deploy/deploy.sh deploy/remote-deploy.sh

echo "==> Building and restarting containers"
./deploy/deploy.sh up -d --build web website
./deploy/deploy.sh up -d --force-recreate caddy

echo "==> Preparing databases (migrate)"
./deploy/deploy.sh exec -T web bin/rails db:prepare

echo "==> Seeding ops admin (if configured)"
./deploy/deploy.sh exec -T web bin/rails db:seed || true

echo "==> Backfilling Stripe customers for Cloud signups"
./deploy/deploy.sh exec -T web bin/rails stripe:backfill_customers || true

echo "==> Pruning old images"
docker image prune -f >/dev/null || true

echo "==> Health checks"
for i in 1 2 3 4 5 6 7 8 9 10; do
  if curl -fsS https://cloud.meerkatagents.com/up >/dev/null && curl -fsS https://meerkatagents.com/up >/dev/null && curl -fsS https://ops.meerkatagents.com/up >/dev/null && curl -fsS https://meerkatagents.com/blog >/dev/null; then
    break
  fi
  sleep 3
done
curl -fsS https://cloud.meerkatagents.com/up >/dev/null
curl -fsS https://meerkatagents.com/up >/dev/null
curl -fsS https://ops.meerkatagents.com/up >/dev/null
curl -fsS https://meerkatagents.com/blog >/dev/null

echo "==> Deploy complete"
