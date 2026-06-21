# Rails Agents

**Agents for your Rails app — without the framework noise.**

Define an agent as a plain Ruby class. Say what it does, pick a provider and model, attach your app code as tools, call `.run`. No dashboards, no cloud accounts, no agent lifecycle UI.

```ruby
class LeadQualifier < RailsAgents::Agent
  provider :openrouter
  model "meta-llama/llama-3.3-70b-instruct:free"
  description "Qualifies inbound leads, answers basic questions, and creates a CRM note when a lead looks promising."
  tools "SearchCrm", "CreateCrmNote"
end

LeadQualifier.run("New signup from acme.com — 50 employees, asked about enterprise pricing")
```

---

## Contents

1. [Philosophy](#philosophy) — what we optimize for and what we skip
2. [The problem](#the-problem) — why this gem exists
3. [How we're different](#how-were-different) — vs RubyLLM and rolling your own
4. [Quick start](#quick-start) — install to first `.run` in minutes
5. [Agents](#agents) — the only class you need
6. [Tools](#tools) — wire in your app code
7. [Skills](#skills) — built-in capabilities (web search, spreadsheets, …)
8. [Providers](#providers) — OpenAI, Anthropic, OpenRouter, Grok
9. [Try it](#try-it) — tests, playground app, recipes
10. [Requirements](#requirements)

---

## Philosophy

Rails Agents competes on **simplicity** — not on having the most features.

We believe the best agent framework for Rails is the one that gets out of your way: a small gem, a familiar DSL, and a straight line from idea to working code.

### What we optimize for

| Priority | What it means in practice |
|----------|---------------------------|
| **Developer experience** | One mental model, one agent class, a DSL that reads like Ruby |
| **Speed to implementation** | `rails generate`, drop a class in `app/agents/`, call `.run` — minutes, not days |
| **Lightweight** | API keys in an initializer, agents in your app — no engine, no control plane, no telemetry stack |
| **Ease of getting started** | Three required declarations: `provider`, `model`, `description`. Everything else is optional |
| **Rails-native** | Your tools are your models, jobs, and services — wired in with plain Ruby classes |

### What we deliberately don't build

Chat persistence, model registries, agent versioning, hosted dashboards, or a general-purpose AI toolkit. Other gems do those well. We stay focused on one job:

> **Get a working agent into your Rails app with the least code and the least ceremony.**

### Who this is for

- You want an agent **today**, not after reading a framework manual
- You already have Rails app code you want the model to call
- You prefer **one class per use case** over configuring agent types, versions, and lifecycles
- You want provider differences handled for you, without giving up control of your agents

---

## The problem

You want AI agents in your Rails app — to answer questions, run workflows, qualify leads, draft emails. Most options push you toward:

| Pain | What you get instead |
|------|----------------------|
| **Heavy setup** | Dashboards, provider wizards, version management, hosted control planes |
| **Framework sprawl** | Different APIs per provider, per agent type, per use case |
| **Unclear starting point** | "Which class do I use? What's an agent version? Where does configuration live?" |

**What you actually want:** define an agent in Ruby, connect your existing code as tools, call `.run`.

Rails Agents is built for exactly that.

---

## How we're different

### vs RubyLLM

[RubyLLM](https://rubyllm.com) is an excellent general-purpose AI framework — chat, images, embeddings, 800+ models, Rails chat persistence. It's the right choice when you want a **full AI toolkit**.

| | **RubyLLM** | **Rails Agents** |
|---|-------------|------------------|
| **Goal** | Broad AI framework | **Agents only** — smallest path to a working agent |
| **Mental model** | `RubyLLM.chat` + `RubyLLM::Agent` with many macros | One class: `RailsAgents::Agent` |
| **Configuration** | API keys + model registry + many options | API keys in initializer; **model on each agent** |
| **What defines behavior** | `instructions`, `tools`, `model`, `temperature`, etc. | **`description`** — what the agent does |
| **Agent types** | You compose behavior yourself | Same class — change `description` for each use case |
| **Tools** | Tool classes / blocks | `RailsAgents::Tool` + auto-load from `app/agents/tools/` |
| **Providers** | Many built-in | OpenAI, Anthropic, OpenRouter, Grok — unified DSL, gem translates API calls |
| **Rails integration** | `acts_as_chat`, persistence | Lightweight: initializer + `app/agents/` |

**Use RubyLLM** if you need multimodal AI, embeddings, model discovery, or chat persistence.

**Use Rails Agents** if you want the fastest path from `gem install` to a working agent — one class, one description, your tools, done.

### vs rolling your own

You could wire OpenAI or Anthropic HTTP calls directly. Rails Agents gives you a thin, opinionated layer so you don't re-solve:

- Multi-turn tool loops
- Provider-specific request/response shapes
- Anthropic skills, server tools, and file downloads
- Portable fallbacks when a skill isn't native to your provider

The gem stays small on purpose. You keep full control of your agents and tools; we handle the plumbing.

---

## Quick start

### 1. Install

```ruby
# Gemfile
gem "rails_agents"
```

```bash
bundle install
bin/rails generate rails_agents:install
```

This creates:

- `config/initializers/rails_agents.rb` — API keys only
- `app/agents/` and `app/agents/tools/` — where your agents live

### 2. Configure API keys

The initializer holds **API keys only**. Models are set on each agent.

```ruby
# config/initializers/rails_agents.rb
RailsAgents.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.openrouter_api_key = ENV["OPENROUTER_API_KEY"]
  config.grok_api_key = ENV["XAI_API_KEY"]
end
```

Set only the keys you use.

### 3. Define and run an agent

Every agent needs three things — nothing more to get started:

```ruby
# app/agents/support_agent.rb
class SupportAgent < RailsAgents::Agent
  provider :openai                    # :openai, :anthropic, :openrouter, :grok
  model "gpt-4o-mini"                 # required — set per agent
  description "Answers customer questions using docs and account data."
  tools "SearchDocs", "LookupAccount" # optional
end
```

```bash
export OPENAI_API_KEY=sk-...
bin/rails console
```

```ruby
result = SupportAgent.run("How do I reset my password?")
result.output   # => the agent's reply
result.success  # => true/false
```

That's it. Add tools and skills when you need them — not before.

---

## Agents

`RailsAgents::Agent` is the only agent class. Each use case is a new subclass with its own `description` — not a new framework concept.

```ruby
class EmailDrafter < RailsAgents::Agent
  provider :anthropic
  model "claude-sonnet-4-20250514"
  description "Draft short, professional follow-up emails from bullet points."
end

class LeadQualifier < RailsAgents::Agent
  provider :openrouter
  model "meta-llama/llama-3.3-70b-instruct:free"
  description "Qualify inbound leads and create CRM notes for promising ones."
  tools "SearchCrm", "CreateCrmNote"
end
```

### Run API

All equivalent:

```ruby
SupportAgent.run("question")
SupportAgent.ask("question")
SupportAgent.call("question")
```

### Result object

```ruby
result.output    # agent's text reply
result.success   # true/false
result.error     # error message when success is false
result.files     # generated files (Anthropic document skills)
```

Pass `save_files_to:` to write downloaded files to disk:

```ruby
ReportBuilder.run("Create Q1 sales report", save_files_to: "tmp/reports")
```

---

## Tools

**Tools** are your app code — the agent calls them when it needs data or side effects.

Drop tool classes in `app/agents/tools/` (auto-loaded) or declare them on the agent:

```ruby
# app/agents/tools/search_docs.rb
class SearchDocs < RailsAgents::Tool
  description "Search product documentation"
  param :query, :string

  def call(query:)
    Documentation.search(query).limit(5).pluck(:title)
  end
end

# app/agents/doc_agent.rb
class DocAgent < RailsAgents::Agent
  provider :openai
  model "gpt-4o-mini"
  description "Answer questions using internal docs."
  tools "SearchDocs"
end
```

**Tip:** Declare tools as **strings** when the agent lives in `app/agents/` (e.g. `tools "SearchDocs"`). Ruby otherwise looks up constants under the agent class first (`LeadQualifier::SearchCrm`). You can also use `tools ::SearchDocs`.

---

## Skills

**Skills** are built-in capabilities (web search, spreadsheets, etc.) provided by the gem. **Tools** are your app code.

```ruby
class ResearchAgent < RailsAgents::Agent
  provider :anthropic
  model "claude-sonnet-4-20250514"
  description "Research topics using current web data and internal docs."
  skills :web_search, :web_fetch
  tools "SearchInternalDocs"
end
```

### Built-in skills

| Skill | What it does | Anthropic | OpenAI / OpenRouter / Grok |
|-------|--------------|-----------|----------------------------|
| `:web_search` | Search the web | Native server tool | Portable Ruby tool |
| `:web_fetch` | Read a URL | Native server tool | Portable Ruby tool |
| `:code_execution` | Run code on Anthropic servers | Native | Anthropic only |
| `:memory` | Persistent memory | Native | Anthropic only |
| `:pptx` | Create/edit PowerPoint | Anthropic Agent Skill | Anthropic only |
| `:xlsx` | Create/edit Excel | Anthropic Agent Skill | Anthropic only |
| `:docx` | Create/edit Word | Anthropic Agent Skill | Anthropic only |
| `:pdf` | Generate PDFs | Anthropic Agent Skill | Anthropic only |

On **Anthropic**, skills run on their servers — the gem passes the right API payloads (including document skills and `code_execution` when needed).

On **other providers**, `:web_search` and `:web_fetch` use portable Ruby implementations so the same DSL works everywhere.

### Skill options

```ruby
skills :web_search, max_uses: 5, allowed_domains: ["wikipedia.org"]
# or
skills web_search: { max_uses: 5 }, :xlsx
```

### Anthropic document skills + file download

Document skills (`:pptx`, `:xlsx`, `:docx`, `:pdf`) run on Anthropic's servers. Generated files are **automatically downloaded** via the Files API:

```ruby
class ReportBuilder < RailsAgents::Agent
  provider :anthropic
  model "claude-sonnet-4-20250514"
  description "Build a quarterly sales spreadsheet with charts."
  skills :xlsx
end

result = ReportBuilder.run("Create Q1 sales report", save_files_to: "tmp/reports")
result.output                       # => "Created your spreadsheet..."
result.files.first.filename         # => "report.xlsx"
result.files.first.path             # => "tmp/reports/report.xlsx"
```

```ruby
RailsAgents.configure do |config|
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.anthropic_auto_download_files = true  # default
  config.anthropic_files_directory = Rails.root.join("tmp/rails_agents/files")
end
```

`:pptx`, `:xlsx`, `:docx`, and `:pdf` automatically enable `code_execution`, attach Anthropic's published skills, and include the required beta headers.

### Custom Anthropic skills

Upload skills via the [Anthropic Skills API](https://platform.claude.com/docs/en/build-with-claude/skills-guide), then reference by ID:

```ruby
skills :web_search, "skill_01AbCdEfGhIjKlMnOpQrStUv"
```

---

## Providers

| Provider | API key | Example model |
|----------|---------|---------------|
| `:openai` | `openai_api_key` | `"gpt-4o-mini"` |
| `:anthropic` | `anthropic_api_key` | `"claude-sonnet-4-20250514"` |
| `:openrouter` | `openrouter_api_key` | `"meta-llama/llama-3.3-70b-instruct:free"` |
| `:grok` | `grok_api_key` | `"grok-2-latest"` |

OpenRouter gives access to hundreds of open-source models through one API key — useful for trying agents without committing to a single vendor.

---

## Try it

### Run the test suite (no API keys)

Tests use fakes and WebMock — fast, no network:

```bash
git clone <repo>
cd rails-agents
bundle install
bin/test
```

### Sample playground app

A minimal Rails app at `spec/dummy/` for trying agents in a browser or console:

```bash
bin/setup
cd spec/dummy
export OPENAI_API_KEY=sk-...
export ANTHROPIC_API_KEY=sk-ant-...   # WebResearchAgent, SheetBuilderAgent
bin/rails server
```

Open **http://localhost:3000** — pick an agent, send input, inspect the result.

| Agent | What it demonstrates |
|-------|----------------------|
| `HelloAgent` | OpenAI, basic `.run` |
| `LeadQualifier` | Custom tools |
| `WebResearchAgent` | Anthropic `:web_search` skill |
| `SheetBuilderAgent` | Anthropic `:xlsx` skill + file download |

See [`spec/dummy/README.md`](spec/dummy/README.md) for console examples.

> **Note:** Running agents in the playground calls live APIs and can take several seconds. The page itself loads instantly; only the "Run agent" action hits the network.

### Recipes

**Tools:**

```ruby
# app/agents/tools/current_time.rb
class CurrentTime < RailsAgents::Tool
  description "Returns the current time in UTC"
  def call = Time.now.utc.iso8601
end

class ClockAgent < RailsAgents::Agent
  provider :openai
  model "gpt-4o-mini"
  description "Tell the user the current time using the tool."
  tools "CurrentTime"
end

ClockAgent.run("What time is it?")
```

**OpenRouter (free models):**

```ruby
class CheapAgent < RailsAgents::Agent
  provider :openrouter
  model "meta-llama/llama-3.3-70b-instruct:free"
  description "Answer briefly."
end

CheapAgent.run("What is Rails?")
```

---

## Requirements

- Ruby 3.2+
- Rails 7.1+

---

## License

MIT
