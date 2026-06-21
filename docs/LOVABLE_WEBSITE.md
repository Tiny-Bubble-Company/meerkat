# Meerkat — Lovable website update brief

Use this document to refresh the marketing site at **https://meerkatagents.com** so it matches the open-source product and BYOK Cloud offering.

---

## GitHub repo — About section (right sidebar)

Set these in **GitHub → your repo → ⚙️ About**:

| Field | Value |
|-------|-------|
| **Description** | Open source webhook-native API for async agent tasks — monitor URLs, track deliveries, BYOK LLM keys. |
| **Website** | `https://meerkatagents.com` |
| **Topics** | `agents`, `webhooks`, `api`, `rails`, `open-source`, `monitoring`, `llm`, `automation`, `task-scheduler` |

---

## Site positioning (one line)

**Meerkat is open source infrastructure that runs agent tasks async and POSTs results to your webhook — bring your own LLM key.**

---

## Hero section

**Headline:** Describe work in plain English. Meerkat runs it async.

**Subhead:** Open source API for developers who need agents to monitor links, track deliveries, and report findings — without building schedulers, webhook plumbing, or LLM tool loops.

**Primary CTA:** Sign up free → `https://meerkatagents.com/signup` (or your Cloud URL)

**Secondary CTAs:**
- Read the docs
- View on GitHub
- Deploy your own (anchor to deploy section)

**Badge line:** Open source · MIT · BYOK · Webhook-native

---

## Deploy section (new — prominent on homepage)

**Headline:** Deploy your own in one click

**Body:** Self-host Meerkat with the same API as Cloud. You run Postgres and workers; users connect their own LLM keys.

**Buttons (link out):**
- **Deploy to Render** → `https://render.com/deploy?repo=https://github.com/Tiny-Bubble-Company/meerkat`
- **Deploy to Fly.io** → `https://fly.io/launch?source=https://github.com/Tiny-Bubble-Company/meerkat`
- **Docker Compose** → GitHub README `#getting-started--docker-recommended`

Replace `Tiny-Bubble-Company/meerkat` with the real GitHub path before publishing.

---

## Self-host vs Cloud (two-column comparison)

### Open source (self-host)
- Free — MIT license
- Docker, Render, Fly.io, or Kamal
- Full REST API + webhook delivery
- Users bring LLM keys (BYOK)
- You operate Postgres + job workers

**CTA:** View on GitHub

### Meerkat Cloud
- Same API — no workers to run
- Managed queues and webhook delivery
- BYOK — Anthropic, OpenAI, OpenRouter, or Grok
- LLM usage billed by your provider
- Monthly subscription for infrastructure

**CTA:** Sign up free

---

## BYOK section (new)

**Headline:** Bring your own LLM key

**Body:** Meerkat never resells AI tokens. Each account connects an encrypted API key. Model costs go to your provider; Meerkat charges for scheduling, execution, and webhooks only.

**Supported providers:**

| Provider | Default model |
|----------|---------------|
| Anthropic | claude-sonnet-4-20250514 |
| OpenAI | gpt-4o-mini |
| OpenRouter | meta-llama/llama-3.3-70b-instruct:free |
| Grok / xAI | grok-3-mini |

---

## How it works (4 steps)

1. **Register** — `POST /tasks` with a plain-English description, input params, and webhook URL
2. **Connect LLM** — Add your provider API key (encrypted at rest)
3. **Run** — Agent executes on a schedule or on demand
4. **Webhook** — Structured JSON POSTed to your URL

---

## Use cases (keep / refresh)

- **Courier tracking** — Pass a DHL/FedEx URL; get webhooks when status changes
- **Price & stock alerts** — Monitor product pages for price or availability shifts
- **Page change detection** — Watch competitor pages, docs, or status sites

---

## Task types

- **recurring** — Scheduled monitors with change detection (courier, uptime, price watches)
- **one_off** — Run once and complete (ad-hoc lookups)

---

## API highlight (short)

- `POST /api/v1/signup` — Create account + API key
- `POST /api/v1/tasks` — Register a task
- `POST /api/v1/tasks/:id/run` — Trigger a run
- `GET /api/v1/tasks/:id/events` — Webhook delivery history

Link to full docs: `/docs` or `https://meerkatagents.com/docs`

---

## Footer

Open source agentic task API · [GitHub](https://github.com/Tiny-Bubble-Company/meerkat) · [Meerkat Cloud](https://meerkatagents.com)

---

## Tone & design notes for Lovable

- **Audience:** Backend developers, not no-code users
- **Tone:** Direct, infra-focused — like Stripe or Checkly, not like a chatbot product
- **Avoid:** “AI platform”, “included credits”, “chat with your data”
- **Prefer:** “webhook-native”, “BYOK”, “open source”, “task API”, “self-host or Cloud”
- **Colors:** Keep existing dark theme + yellow accent if already set
- **Social proof placeholder:** GitHub stars badge, “Deploy to Render” button

---

## URLs checklist before go-live

- [ ] GitHub repo URL updated in all deploy buttons
- [ ] `meerkatagents.com` points to Cloud signup + docs
- [ ] GitHub About description + website link set
- [ ] Render deploy tested (`RAILS_MASTER_KEY` set in dashboard)
- [ ] Fly deploy tested (`fly secrets set RAILS_MASTER_KEY=...`)
