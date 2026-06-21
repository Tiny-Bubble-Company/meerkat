# Meerkat

**Open source agentic task infrastructure API for developers**

Register async agent tasks in plain English. Meerkat executes them on a schedule or on demand and POSTs structured findings to your webhook — without you building schedulers, LLM tool loops, or webhook plumbing yourself.

> **Self-host** with Docker, Render, or Fly.io — or use **[Meerkat Cloud](https://meerkatagents.com)** (same API, no workers to run).

<p align="center">
  <a href="https://render.com/deploy?repo=https://github.com/Tiny-Bubble-Company/meerkat">
    <img src="https://render.com/images/deploy-to-render-button.svg" alt="Deploy to Render" height="32">
  </a>
  &nbsp;
  <a href="https://fly.io/launch?source=https://github.com/Tiny-Bubble-Company/meerkat">
    <img src="https://img.shields.io/badge/Deploy%20to%20Fly.io-8b5cf6?style=for-the-badge&logo=fly.io&logoColor=white" alt="Deploy to Fly.io" height="32">
  </a>
  &nbsp;
  <a href="https://github.com/Tiny-Bubble-Company/meerkat#getting-started--docker-recommended">
    <img src="https://img.shields.io/badge/Self--host%20with%20Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Self-host with Docker" height="32">
  </a>
</p>

---

## Table of contents

- [What is Meerkat?](#what-is-meerkat)
- [Self-host vs Meerkat Cloud](#self-host-vs-meerkat-cloud)
- [How it works](#how-it-works)
- [Use cases](#use-cases)
- [Task types](#task-types)
- [Getting started — Docker (recommended)](#getting-started--docker-recommended)
- [Deploy to Render (one-click)](#deploy-to-render-one-click)
- [Deploy to Fly.io (one-click)](#deploy-to-flyio-one-click)
- [Getting started — local development](#getting-started--local-development)
- [LLM providers (BYOK)](#llm-providers-byok)
- [Configuration reference](#configuration-reference)
- [API overview](#api-overview)
- [Example API calls](#example-api-calls)
- [Output formats](#output-formats)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [OpenAPI spec](#openapi-spec)
- [Production deployment](#production-deployment)
- [Related projects](#related-projects)
- [License](#license)

---

## What is Meerkat?

Meerkat gives you a single primitive for agentic async work:

```
Register a task → Meerkat runs it → findings POST to your webhook
```

You describe the work in natural language, pass structured `input_params`, and Meerkat's agent executes it. The agent picks tools (webpage fetch, etc.), extracts structured findings, and delivers them as JSON to your `output_webhook`.

```json
POST /api/v1/tasks
{
  "task": {
    "task_type": "recurring",
    "description": "Monitor DHL tracking and report status changes",
    "input_params": { "courier_tracking_link": "https://..." },
    "frequency": "every 2 hours",
    "output_webhook": "https://your-app.com/hook"
  }
}
```

---

## Self-host vs Meerkat Cloud

| | Self-host (OSS) | Meerkat Cloud |
|--|-----------------|---------------|
| **API** | ✅ identical | ✅ identical |
| **LLM keys** | You supply (any provider) | You supply (BYOK) |
| **Infra / ops** | You run Postgres + workers | Managed for you |
| **Docker support** | ✅ `docker compose up` | — |
| **Kamal deploy** | ✅ included | — |
| **Support** | GitHub Issues | Email / SLA |
| **Cost** | Your infra + LLM bills | Monthly subscription |

LLM usage is always billed by **your provider** (Anthropic, OpenAI, OpenRouter, or Grok). Meerkat never sees your model costs.

---

## How it works

```
┌─────────────┐     POST /tasks      ┌─────────────┐     agent + tools    ┌─────────────┐
│  Your app   │ ──────────────────►  │   Meerkat   │ ──────────────────►  │  Web / APIs │
└─────────────┘                      └─────────────┘                      └─────────────┘
       ▲                                     │
       │         POST output_webhook         │
       └─────────────────────────────────────┘
```

| Step | What happens |
|------|--------------|
| **1. Register** | `POST /api/v1/tasks` — describe work, pass params, set webhook |
| **2. Run** | Meerkat schedules recurring tasks or runs one-offs on demand |
| **3. Return** | Findings POSTed to your webhook as structured JSON |

---

## Use cases

### Courier & delivery tracking
Pass a tracking URL. Meerkat fetches the page, extracts status/location/ETA, and webhooks you on meaningful changes.

### Price & stock alerts
Monitor a product page. Get notified when price, availability, or content shifts.

### Page change detection
Watch competitor pages, documentation, or status sites across runs.

### Ad-hoc lookups
One-off tasks to fetch and extract data without setting up a schedule.

---

## Task types

| Type | Behavior | Best for |
|------|----------|----------|
| `recurring` | Runs on a schedule; compares state between runs; reports changes | Courier tracking, uptime, price watches |
| `one_off` | Runs once, reports findings, marks task complete | Ad-hoc research, single lookups |

**Frequency** accepts natural language (`every 30 minutes`, `hourly`, `every 2 hours`) or cron expressions.

---

## Getting started — Docker (recommended)

The fastest way to self-host. You need Docker and a `RAILS_MASTER_KEY`.

### 1. Clone and configure

```bash
git clone https://github.com/Tiny-Bubble-Company/meerkat.git
cd meerkat
cp .env.example .env.production
```

Edit `.env.production`:

```bash
# Required
RAILS_MASTER_KEY=<contents of config/master.key>
POSTGRES_PASSWORD=choose-a-strong-password

# LLM — leave blank if all your users bring their own keys (BYOK)
# Set one to use as a server-level fallback in development only.
# ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...
# OPENROUTER_API_KEY=sk-or-...
# XAI_API_KEY=xai-...
# MEERKAT_DEFAULT_LLM_PROVIDER=anthropic
```

### 2. Start

```bash
docker compose --env-file .env.production up -d
```

Meerkat starts at **http://localhost:3000**. The database is created and migrated automatically on first boot.

### 3. Sign up and connect your LLM key

1. Go to `http://localhost:3000/signup`
2. Complete onboarding — you'll be prompted to add your **LLM API key** (Anthropic, OpenAI, OpenRouter, or Grok)
3. Create your first task and trigger a run — findings POST to your webhook

### 4. Start building

```bash
# Create a task via API
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Authorization: Bearer mk_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "task": {
      "task_type": "one_off",
      "description": "Fetch the page title and main heading",
      "input_params": { "url": "https://example.com" },
      "output_webhook": "https://webhook.site/your-id"
    }
  }'
```

### Docker compose reference

```bash
docker compose up -d          # start in background
docker compose logs -f web    # follow logs
docker compose down           # stop
docker compose down -v        # stop + delete data
docker compose build          # rebuild image after code changes
```

---

## Deploy to Render (one-click)

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/Tiny-Bubble-Company/meerkat)

1. Click **Deploy to Render** (update the repo URL if you forked).
2. Render reads [`render.yaml`](render.yaml) and provisions Postgres + the web service.
3. In the Render dashboard, set **`RAILS_MASTER_KEY`** to the content of `config/master.key`.
4. Wait for deploy — visit your Render URL and sign up.
5. Connect your LLM key during onboarding (BYOK).

Sibling databases (`_queue`, `_cache`, `_cable`) are created automatically from `DATABASE_URL` on boot.

---

## Deploy to Fly.io (one-click)

[![Deploy to Fly.io](https://img.shields.io/badge/Deploy%20to%20Fly.io-8b5cf6?style=for-the-badge&logo=fly.io&logoColor=white)](https://fly.io/launch?source=https://github.com/Tiny-Bubble-Company/meerkat)

1. Click **Deploy to Fly.io** or run `fly launch` from the repo root.
2. Fly reads [`fly.toml`](fly.toml) and builds the Docker image.
3. Create and attach Postgres:
   ```bash
   fly postgres create --name meerkat-db
   fly postgres attach meerkat-db
   ```
4. Set secrets:
   ```bash
   fly secrets set RAILS_MASTER_KEY=$(cat config/master.key)
   ```
5. Deploy: `fly deploy` — visit your Fly URL and sign up.

---

## Getting started — local development

### Prerequisites

- Ruby 3.2+ (see `.ruby-version`)
- PostgreSQL 14+
- An API key from Anthropic, OpenAI, OpenRouter, or Grok

### Install

```bash
git clone https://github.com/Tiny-Bubble-Company/meerkat.git
cd meerkat
bundle install
cp .env.example .env
```

Edit `.env` — add at least one LLM key for local dev:

```bash
ANTHROPIC_API_KEY=sk-ant-...     # or OPENAI_API_KEY / OPENROUTER_API_KEY / XAI_API_KEY
MEERKAT_DEFAULT_LLM_PROVIDER=anthropic
```

### Set up and run

```bash
bin/rails db:prepare

# Option A — server + jobs in one process (simplest):
bin/dev

# Option B — separate terminals:
bin/rails server          # terminal 1
bin/jobs                  # terminal 2
```

Visit [http://localhost:3000](http://localhost:3000).

> **Note:** In local dev, if `ANTHROPIC_API_KEY` (or another provider key) is set in `.env`, Meerkat uses it as a fallback so you can test without going through BYOK onboarding. In production, each user must connect their own key.

### Reset database

```bash
# Stop Rails first, then:
psql postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname LIKE 'meerkat_%' AND pid <> pg_backend_pid();"
bin/rails db:reset
```

---

## LLM providers (BYOK)

Meerkat is **bring-your-own-key**. Every user connects their own LLM provider during onboarding. Keys are encrypted at rest and never exposed by the API.

| Provider | Key prefix | Default model | Get a key |
|----------|-----------|---------------|-----------|
| **Anthropic** | `sk-ant-` | `claude-sonnet-4-20250514` | [console.anthropic.com/keys](https://console.anthropic.com/keys) |
| **OpenAI** | `sk-` | `gpt-4o-mini` | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| **OpenRouter** | `sk-or-` | `meta-llama/llama-3.3-70b-instruct:free` | [openrouter.ai/keys](https://openrouter.ai/keys) |
| **Grok / xAI** | `xai-` | `grok-3-mini` | [console.x.ai](https://console.x.ai/) |

Users can override the model per account from the **Docs → LLM Provider** settings page.

### How BYOK works in the code

When a task runs, `Agents::RunForCustomer` resolves the customer's encrypted key and builds a provider-specific client — no global key is used. See `app/services/agents/run_for_customer.rb`.

---

## Configuration reference

Copy `.env.example` to `.env` (local dev) or `.env.production` (Docker):

| Variable | Required | Description |
|----------|----------|-------------|
| `RAILS_MASTER_KEY` | **Docker/prod** | Content of `config/master.key` |
| `DATABASE_URL` | Docker/prod | Full Postgres connection URL |
| `SOLID_QUEUE_IN_PUMA` | No | `1` = run job workers inside Puma (recommended for single-server) |
| `ANTHROPIC_API_KEY` | Dev fallback | Anthropic key for local dev without BYOK |
| `OPENAI_API_KEY` | Dev fallback | OpenAI key for local dev without BYOK |
| `OPENROUTER_API_KEY` | Dev fallback | OpenRouter key for local dev without BYOK |
| `XAI_API_KEY` | Dev fallback | Grok/xAI key for local dev without BYOK |
| `MEERKAT_DEFAULT_LLM_PROVIDER` | No | Default provider for dev fallback (`anthropic`, `openai`, `openrouter`, `grok`) |
| `MEERKAT_FAILURE_THRESHOLD` | No | Consecutive failures before task marked failed (default: `5`) |
| `MEERKAT_WEBHOOK_TIMEOUT` | No | Webhook HTTP timeout in seconds (default: `15`) |
| `MEERKAT_CORS_ORIGINS` | No | CORS allowed origins (default: `*`) |

WhatsApp delivery (optional) requires Twilio credentials — see `.env.example`.

---

## API overview

Base URL: `http://localhost:3000/api/v1`

All endpoints except `POST /signup` require `Authorization: Bearer mk_YOUR_KEY`.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/signup` | Create account + receive API key (shown once) |
| `GET` | `/api_keys` | List your API keys |
| `POST` | `/api_keys` | Generate a new key |
| `DELETE` | `/api_keys/:id` | Revoke a key |
| `GET` | `/tasks` | List tasks (`task_type`, `status`, `limit`, `offset`) |
| `POST` | `/tasks` | Create a task |
| `GET` | `/tasks/:id` | Task details + last known state |
| `PATCH` | `/tasks/:id` | Partial update |
| `PUT` | `/tasks/:id` | Full replace |
| `DELETE` | `/tasks/:id` | Archive or permanently delete |
| `POST` | `/tasks/:id/run` | Trigger an on-demand run |
| `POST` | `/tasks/:id/pause` | Pause a recurring task |
| `POST` | `/tasks/:id/resume` | Resume a paused task |
| `GET` | `/tasks/:id/runs` | List runs for a task |
| `GET` | `/tasks/:id/events` | Webhook delivery history |
| `GET` | `/openapi` | OpenAPI 3.1 YAML spec |

---

## Example API calls

### 1. Sign up

```bash
curl -X POST http://localhost:3000/api/v1/signup \
  -H "Content-Type: application/json" \
  -d '{"customer":{"email":"you@company.com","name":"Your Name"}}'
```

Response includes `api_key` — **store it securely; shown once**.

### 2. Create a recurring courier monitor

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Authorization: Bearer mk_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "task": {
      "task_type": "recurring",
      "description": "Monitor DHL tracking and report status changes",
      "input_params": {
        "courier_tracking_link": "https://www.dhl.de/de/privatkunden/pakete-empfangen/verfolgen.html?piececode=00340434293251802213"
      },
      "frequency": "every 2 hours",
      "output_webhook": "https://your-app.com/hook"
    }
  }'
```

### 3. Create a one-off task

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Authorization: Bearer mk_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "task": {
      "task_type": "one_off",
      "description": "Fetch the current price of this product",
      "input_params": { "url": "https://example.com/product/123" },
      "output_webhook": "https://your-app.com/hook"
    }
  }'
```

### 4. Trigger an on-demand run

```bash
curl -X POST http://localhost:3000/api/v1/tasks/1/run \
  -H "Authorization: Bearer mk_YOUR_KEY"
```

### 5. Inspect runs and webhook events

```bash
curl http://localhost:3000/api/v1/tasks/1/runs   -H "Authorization: Bearer mk_YOUR_KEY"
curl http://localhost:3000/api/v1/tasks/1/events -H "Authorization: Bearer mk_YOUR_KEY"
```

---

## Output formats

`output_webhook` is **required** on every task. `output_format` is optional (default: `default`).

| Preset | Webhook payload shape |
|--------|----------------------|
| `default` | `{ event, task_id, task_run_id, occurred_at, data: { summary, findings, change_detected, ... } }` |
| `compact` | Top-level `summary`, `change_detected`, `findings` |
| `flat` | Findings merged into the webhook root object |
| `findings_only` | Findings object only |
| `minimal` | `event`, `task_id`, `summary`, `change_detected` |

Any other string is passed to the agent as a custom instruction for shaping findings (max 500 chars).

---

## Architecture

```
meerkat/
├── app/
│   ├── agents/              # TaskExecutor agent + tools (FetchWebpage, SendWhatsapp)
│   ├── controllers/
│   │   ├── api/v1/          # JSON API
│   │   ├── docs/            # API key + LLM provider management UI
│   │   └── onboarding/      # Guided first-run wizard
│   ├── jobs/                # ExecuteTaskJob, DeliverWebhookJob, DispatchDueTasksJob
│   ├── models/              # Customer, ApiKey, Task, TaskRun, TaskEvent
│   └── services/
│       ├── agents/          # RunForCustomer (BYOK provider resolution)
│       ├── customers/       # Signup, SaveLlmCredential
│       ├── tasks/           # Create, Run, Execute, Report, ...
│       └── webhooks/        # Deliver, PayloadFormatter
├── config/
│   ├── queue.yml            # Solid Queue workers (monitors + webhooks)
│   └── recurring.yml        # DispatchDueTasks schedule
├── Dockerfile
└── docker-compose.yml
```

### Core models

| Model | Purpose |
|-------|---------|
| `Customer` | Account — holds encrypted LLM key (`llm_provider`, `llm_api_key_ciphertext`, `llm_model`) |
| `ApiKey` | Hashed tokens (`mk_...`), scoped to customer |
| `Task` | Registered work unit (`task_type`, `description`, `input_params`, `frequency`, `output_webhook`, `output_format`) |
| `TaskRun` | Single execution (`pending` → `running` → `succeeded` / `failed`) |
| `TaskEvent` | Audit log + webhook delivery history per run |

### Execution flow

1. **Recurring:** `DispatchDueTasksJob` finds due tasks → enqueues `ExecuteTaskJob`
2. **On-demand:** `POST /tasks/:id/run` → creates `TaskRun` → enqueues `ExecuteTaskJob`
3. **Execute:** `Tasks::Execute` → `Agents::RunForCustomer` resolves BYOK credentials → runs `TaskExecutor` → updates run/task state → `DeliverWebhookJob` POSTs to webhook

---

## Project structure

```
app/
├── agents/
│   ├── task_executor.rb          # Core monitoring agent
│   └── tools/
│       ├── fetch_webpage.rb      # HTTP fetch tool
│       └── send_whatsapp.rb      # Optional Twilio WhatsApp
├── controllers/
│   ├── api/v1/                   # JSON API controllers
│   ├── docs/
│   │   ├── api_keys_controller.rb
│   │   └── llm_providers_controller.rb
│   ├── docs_controller.rb
│   └── onboarding_controller.rb
├── services/
│   ├── agents/run_for_customer.rb  # BYOK provider routing
│   ├── customers/
│   │   ├── signup.rb
│   │   └── save_llm_credential.rb
│   ├── tasks/                    # Create, Run, Execute, Report, ...
│   └── webhooks/                 # Deliver, PayloadFormatter
└── views/
    ├── pages/home.html.erb
    ├── docs/sections/
    └── onboarding/               # api_key → llm_provider → create_task → run_task → waiting → success
```

---

## OpenAPI spec

Full spec: `GET /api/v1/openapi` (YAML)

Local file: [`openapi/openapi.yaml`](openapi/openapi.yaml)

Import into Postman, generate clients, or validate requests against the spec.

---

## Production deployment

### Docker Compose (single server)

```bash
# 1. Copy and fill in secrets
cp .env.example .env.production
# edit .env.production — set RAILS_MASTER_KEY, POSTGRES_PASSWORD

# 2. Deploy
docker compose --env-file .env.production up -d

# 3. Check health
curl http://your-server/up
```

### Kamal (recommended for VPS)

Meerkat ships with [Kamal](https://kamal-deploy.org/) configuration:

```bash
gem install kamal
kamal setup   # first deploy
kamal deploy  # subsequent deploys
```

Edit `config/deploy.yml` with your server IP, Docker registry, and secrets.

### Environment variables in production

Set via your Docker orchestrator or Kamal secrets. At minimum:

```bash
RAILS_MASTER_KEY=...        # from config/master.key
DATABASE_URL=postgresql://...
QUEUE_DATABASE_URL=postgresql://...
SOLID_QUEUE_IN_PUMA=1
```

LLM keys are stored per-customer in the database (BYOK). No server-level LLM key is required in production.

---

## Related projects

Meerkat is built on **[rails-agents](https://github.com/your-org/rails-agents)** — a Ruby gem for defining LLM agents with tools and running them via Active Job in Rails applications.

---

## License

MIT — see [LICENSE](LICENSE).

Self-host for free. For managed hosting with no queue ops, visit [Meerkat Cloud](https://meerkatagents.com).
