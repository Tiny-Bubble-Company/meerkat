# Deploy Meerkat Cloud to Hetzner

Production runs on the Hetzner VPS at `/opt/meerkat-apps/meerkat` via Docker Compose + Caddy.

## Automatic deploy (GitHub Actions)

Every push to `main` (including merged PRs) runs CI, then rsyncs the app to Hetzner and rebuilds containers if checks pass.

The repository is private, so deploy uses **rsync from GitHub Actions** (not `git pull` on the server).

### One-time server setup

1. Ensure DNS points to the server:
   - `meerkatagents.com`, `www.meerkatagents.com`, `cloud.meerkatagents.com`

2. Create production env on the server (secrets stay on the box):

```bash
ssh root@meerkatagents.com
mkdir -p /opt/meerkat-apps/meerkat
cat > /opt/meerkat-apps/meerkat/.env.production <<'EOF'
POSTGRES_PASSWORD=<strong-random-password>
RAILS_MASTER_KEY=<content of config/master.key>
MEERKAT_WEBSITE_URL=https://meerkatagents.com
MEERKAT_CLOUD_URL=https://cloud.meerkatagents.com
MEERKAT_GITHUB_REPO=https://github.com/Tiny-Bubble-Company/meerkat
EOF
chmod 600 /opt/meerkat-apps/meerkat/.env.production
```

3. Add GitHub Actions deploy key to the server:

```bash
# on your laptop — paste the public key into authorized_keys on the server
ssh-keygen -t ed25519 -f ./meerkat-deploy-key -N "" -C "github-actions-meerkat-deploy"
ssh root@meerkatagents.com "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" < ./meerkat-deploy-key.pub
```

4. Add GitHub repository secrets (`Settings → Secrets → Actions`):

| Secret | Value |
|--------|--------|
| `DEPLOY_SSH_KEY` | contents of `meerkat-deploy-key` (private key) |
| `DEPLOY_HOST` | `meerkatagents.com` |
| `DEPLOY_USER` | `root` |

Or with the GitHub CLI:

```bash
gh secret set DEPLOY_SSH_KEY < meerkat-deploy-key
gh secret set DEPLOY_HOST --body "meerkatagents.com"
gh secret set DEPLOY_USER --body "root"
```

5. Push to `main`. The workflow rsyncs the repo to the server and runs:

```bash
./deploy/deploy.sh up -d --build web caddy
```

### Manual deploy

```bash
ssh root@meerkatagents.com 'bash /opt/meerkat-apps/meerkat/deploy/remote-deploy.sh'
```

Or from a local checkout:

```bash
rsync -az --exclude '.git' --exclude 'tmp/' --exclude 'log/' --exclude 'storage/' --exclude '.env*' \
  ./ root@meerkatagents.com:/opt/meerkat-apps/meerkat/
ssh root@meerkatagents.com 'cd /opt/meerkat-apps/meerkat && ./deploy/deploy.sh up -d --build web caddy'
```

## Stack

- **web** — Rails 8 + Thruster/Puma + Solid Queue in Puma
- **db** — Postgres 16
- **caddy** — HTTPS reverse proxy for marketing + cloud hosts

## Health checks

- https://cloud.meerkatagents.com/up
- https://meerkatagents.com/up
