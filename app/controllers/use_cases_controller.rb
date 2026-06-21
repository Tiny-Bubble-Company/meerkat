# frozen_string_literal: true

class UseCasesController < ApplicationController
  layout "home"

  PAGES = {
    "package-tracking" => {
      title: "Package Tracking API — Multi-courier webhook tracking · Meerkat",
      description: "Open source package tracking API. Monitor DHL, UPS, FedEx, USPS and any courier link. Get a signed webhook the moment status changes. BYOK LLM, MIT licensed.",
      og_title: "Package Tracking API · Meerkat",
      og_description: "Webhook-native multi-courier tracking. One API, every carrier, no per-carrier integrations.",
      eyebrow: "Use case · Package tracking",
      headline: "A package tracking API",
      headline_italic: "that fires a webhook the moment status changes.",
      intro: "Monitor any courier tracking link — DHL, UPS, FedEx, USPS, DPD, Royal Mail — with one API. Meerkat's agent reads the carrier's page on a schedule, detects state changes, and POSTs structured JSON to your endpoint. No per-carrier SDKs, no polling code, no LLM tool loops to maintain.",
      bullets: [
        { title: "Every carrier, one endpoint", body: "Pass a courier_tracking_link in plain text. Meerkat handles the rest, so adding a new carrier is zero code." },
        { title: "Webhook on change only", body: "You hear from us when the state moves — In transit → Out for delivery → Delivered. Quiet otherwise." },
        { title: "Signed and retried", body: "HMAC-SHA256 signatures, exponential backoff, idempotency keys. Same delivery guarantees Stripe uses." },
        { title: "BYOK LLM keys", body: "Bring Anthropic, OpenAI, OpenRouter or Grok. You own the spend and the model choice." }
      ],
      code: <<~CURL,
        curl -X POST __API_BASE__/tasks \\
          -H "Authorization: Bearer mk_live_..." \\
          -H "Content-Type: application/json" \\
          -d '{
            "task_type": "recurring",
            "description": "Monitor DHL tracking and report status changes",
            "input_params": {
              "courier_tracking_link": "https://dhl.de/track?id=00340..."
            },
            "frequency": "every 2 hours",
            "output_webhook": "https://your-app.com/hook"
          }'
      CURL
      faqs: [
        { q: "Which couriers are supported?", a: "Any courier with a public tracking page. Meerkat reads the page with an LLM agent, so DHL, UPS, FedEx, USPS, Royal Mail, DPD, Australia Post, Aramex and most regional carriers work without per-carrier integrations." },
        { q: "How often does it check?", a: "Any cadence — every 15 minutes, hourly, every 2 hours, or a custom cron. Meerkat only POSTs to your webhook when the status actually changes, so you don't pay for noise." },
        { q: "Do I need to host anything?", a: "No. Use Meerkat Cloud and bring your own LLM key, or self-host the open source server on Render, Fly.io, or Docker — same API either way." },
        { q: "What does the webhook payload look like?", a: "A signed JSON POST with task_id, status (changed / unchanged / error), and a findings object containing courier, state, ETA, and location. HMAC-SHA256 signed and retried with exponential backoff until 2xx." }
      ]
    },
    "website-monitoring" => {
      title: "Website Change Detection API — Monitor any URL · Meerkat",
      description: "Open source website monitoring API. Detect price drops, stock changes, copy edits, competitor moves. Webhook fires only when your described signal triggers. BYOK.",
      og_title: "Website Change Detection API · Meerkat",
      og_description: "Describe the change you care about in English. Meerkat watches the URL and POSTs when it happens.",
      eyebrow: "Use case · Website monitoring",
      headline: "Watch any URL.",
      headline_italic: "Get a webhook when the thing you care about changes.",
      intro: "A website change detection API that understands intent. Instead of raw diffs, you describe the signal — a price drop, a stock flip, a competitor's pricing page edit — and Meerkat's agent watches on a schedule. It only fires your webhook when the described change actually happens.",
      bullets: [
        { title: "Semantic, not pixel diff", body: "Plain-English conditions like 'price under $99' or 'plan name changed'. No selectors to maintain." },
        { title: "JS-rendered pages", body: "Headless browser rendering means SPAs, React, and dynamic content work out of the box." },
        { title: "Schedule it your way", body: "Cron strings, natural language ('every 15 minutes'), or on-demand POST /tasks/:id/run." },
        { title: "Self-host or Cloud", body: "Same REST API. Run it on Docker, Fly.io, Render — or use Meerkat Cloud with BYOK." }
      ],
      code: <<~CURL,
        curl -X POST __API_BASE__/tasks \\
          -H "Authorization: Bearer mk_live_..." \\
          -d '{
            "task_type": "recurring",
            "description": "Notify me when this product drops below $99",
            "input_params": {
              "url": "https://shop.example.com/widget-pro"
            },
            "frequency": "every 30 minutes",
            "output_webhook": "https://your-app.com/hook"
          }'
      CURL
      faqs: [
        { q: "What kinds of changes can it detect?", a: "Anything an LLM agent can see — price drops, stock status, copy edits, new blog posts, regulatory text updates, competitor pricing pages. You describe the signal in English; Meerkat watches for it." },
        { q: "How is this different from diff-based monitors?", a: "Raw-diff tools fire on every cosmetic change. Meerkat understands semantic intent — 'tell me when the price drops below $99' — and only POSTs when that condition is met." },
        { q: "Can it follow JavaScript-rendered pages?", a: "Yes. The agent renders pages in a headless browser before reasoning, so React, Vue, and SPA-rendered content work the same as static HTML." },
        { q: "What about rate limits and politeness?", a: "Meerkat respects robots.txt, throttles per-domain, and reuses cached fetches across tasks targeting the same URL." }
      ]
    },
    "agent-webhooks" => {
      title: "Async Agent Task API — Webhook-native LLM agents · Meerkat",
      description: "Open source async agent task API. Describe work in English, BYOK an LLM, Meerkat runs it on a schedule and POSTs signed JSON to your webhook. MIT licensed.",
      og_title: "Async Agent Task API · Meerkat",
      og_description: "The webhook-native primitive for async LLM agents. Skip the scheduler and tool-loop boilerplate.",
      eyebrow: "Use case · Async agent webhooks",
      headline: "An agent task API",
      headline_italic: "with webhooks as the first-class output.",
      intro: "Meerkat is an open source async agent framework for engineers who'd rather ship product than rebuild schedulers, LLM tool loops, and webhook delivery. Register a task in plain English, attach your LLM key, point at an endpoint — done.",
      bullets: [
        { title: "One verb: register", body: "POST /v1/tasks creates a recurring or one-off agent task. Everything else is operational." },
        { title: "Webhook-native results", body: "Structured JSON, signed, retried with exponential backoff. The same delivery contract you already handle for Stripe or GitHub." },
        { title: "BYOK keys, per-task", body: "Encrypted at rest, scoped per task. Cost and rate limits stay yours." },
        { title: "MIT and self-hostable", body: "Open source server, Docker compose, one-click Render and Fly deploys. No vendor lock-in." }
      ],
      code: <<~CURL,
        curl -X POST __API_BASE__/tasks \\
          -H "Authorization: Bearer mk_live_..." \\
          -d '{
            "task_type": "recurring",
            "description": "Summarize new arXiv papers in distributed systems",
            "input_params": { "topic": "distributed systems" },
            "frequency": "0 9 * * *",
            "output_webhook": "https://your-app.com/hook"
          }'
      CURL
      faqs: [
        { q: "Why not run agents in my own backend?", a: "You can — but you'll rebuild scheduling, tool-loop orchestration, retries, idempotency, signed delivery, and per-task LLM key isolation. Meerkat is the open source primitive for exactly that stack." },
        { q: "What LLM providers are supported?", a: "Anthropic, OpenAI, OpenRouter, and Grok at launch. Keys are BYOK and encrypted at rest. Add a provider once; reuse across every task." },
        { q: "Is the API stable?", a: "POST /v1/tasks, GET /v1/tasks/:id, and POST /v1/tasks/:id/run are the core verbs. Versioned URL prefix, semver, and a deprecation policy documented in the repo." },
        { q: "How are webhooks verified?", a: "Every outbound POST is HMAC-SHA256 signed with your endpoint secret in the X-Meerkat-Signature header. SDKs ship a verify() helper." }
      ]
    }
  }.freeze

  def show
    @page = PAGES.fetch(params[:slug]) { raise ActionController::RoutingError, "Not Found" }
    @page = @page.deep_dup
    @page[:code] = @page[:code].gsub("__API_BASE__", api_base_url)
  end
end
