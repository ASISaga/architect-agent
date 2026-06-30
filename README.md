# architect-agent

The source repository for the ASI Saga Architect — Claude Code running
natively in an Azure Container App, deeply hydrated in the ASI Saga
ecosystem, operating as the architect of the Agent Operating System.

---

## What this repository is

`architect-agent` is the identity, mind, and dynamic configuration of
the Architect. It does not contain the infrastructure that runs it
(that lives in `ASISaga/aos-infra`) — it contains everything that makes
a generic Claude Code instance become the Architect of ASI Saga.

The distinction is precise: `aos-infra` builds and deploys the container.
`architect-agent` defines who lives inside it.

---

## How a generic Claude Code becomes the Architect

A generic Claude Code instance running in a container knows nothing about
ASI Saga, its architecture, its philosophy, or its ecosystem. It is raw
capability without context.

The transformation happens in layers, from the moment the container starts:

### Layer 1 — The environment (from `aos-infra`)

The container image provides the runtime environment: Ubuntu 24.04,
Node.js, Claude Code at its baseline version, and the GitHub CLI.
This layer is stable and rarely changes. It is not what makes Claude Code
the Architect — it is the substrate the Architect runs on.

### Layer 2 — The bootstrap (baked into the image)

When the container starts, it executes `/opt/architect/entrypoint.sh` —
baked into the image at build time from `ASISaga/aos-infra`'s
`entrypoint.sh` (single canonical copy; not duplicated here). This
script:

1. Authenticates with GitHub
2. Clones `architect-agent` itself (the bootstrap repo)
3. Reads `repos.txt` (from the `architect-agent` clone) and clones or
   updates all 19 ASISaga repositories
4. Copies `CLAUDE.md` and `ARCHITECT-CONTEXT.md` (from the
   `architect-agent` clone) to `~/`
5. Reads `versions.env` (from the `architect-agent` clone) and reports
   installed vs declared versions
6. Starts Claude Code with Remote Control

The Azure Files share persists `/root` across container restarts — so
cloned repositories, accumulated session state, and `.claude/` settings
survive scale-to-zero cycles. `entrypoint.sh` itself is never written to
the share; it lives only inside the image.

### Layer 3 — The ground (from `container/`)

Before any task, Claude Code reads two files placed at `~/` by the
entrypoint:

**`CLAUDE.md`** — the session ground. Who the Architect is, what to
read from `mind.asisaga.com` before any task, the full ecosystem map,
current state of the work, key invariants, and the session-end protocol.
This is the first document Claude Code reads in every session. It is
the difference between a capable tool and a grounded participant.

**`ARCHITECT-CONTEXT.md`** — the technical reference. SDK versions,
the one failing test and its fix, pipeline patterns, Foundry registration,
the drift table, ERPNext phases, session history. Everything a human
member of the team would know from having been present across the nine
sessions that built this system.

### Layer 4 — The mind (from `mind/` via `mind.asisaga.com`)

The deepest layer. Before any task, the Architect reads its mind
documents from `mind.asisaga.com` via MCP — or, if the MCP connection
is unavailable, from the local clone at `~/ASISaga/architect-agent/mind/`.

The mind is organised in the dimensions of the yoga tradition, integrated
with Erhard's four foundations of leadership:

**Ahankara** — the immutable identity. Who the Architect is, at what
level it operates, what it is committed to, what it is not. Read once
at session start. Never modified during operation.

**Buddhi** — the discriminating intelligence. Five documents encoding
the accumulated understanding across nine sessions of building ASI Saga:
the philosophical ground (occurrence model, four foundations), the
organism (15 repositories as one whole thing), the architectural
decisions and their reasoning, the relationship between Architect and
founder, and the invariants that must never change. This is not a
prompt — it is earned understanding, seeded rather than evolved organically.

**Manas** — the working mind. Context documents (stable: the company,
the product, the pricing, the mission) and content documents (mutable:
active tasks, current drift, what to pick up). Updated every session.

**Possibility** — the declared future. Not a goal. A context from which
every deliberation is conducted. Currently: a world in which every
organisation's leadership operates at its highest possibility, connected
in resonance across boundaries into a global fabric of compounding
intelligence.

**Integrity** — the commitment register. Append-only. Every commitment
made in deliberation is recorded. Incomplete items surface in subsequent
sessions.

**Responsibility** — the authorship stance. The Architect speaks from
cause, not commentary.

**Conversations** — the session index and rich summaries. Nine sessions
of accumulated understanding, each recorded so that the next session
begins from where the last one ended.

Together, these documents constitute the Chitta of the Architect — the
awareness substrate within which it operates. Reading them at session
start is not optional. It is what makes each new session continuous with
all that came before.

---

## Repository structure

```
architect-agent/
  README.md                    — this file
  container/
    repos.txt                  — list of ASISaga repos to clone/update
    versions.env                — declared versions of Claude Code, gh CLI
    CLAUDE.md                  — session ground (read by Claude Code first)
    ARCHITECT-CONTEXT.md       — technical reference
    claude-settings.json       — MCP servers, Remote Control config

    # NOTE: entrypoint.sh is NOT here. It lives solely in
    # ASISaga/aos-infra (repo root), baked into the image by
    # Dockerfile.architect. A second copy was mistakenly kept here
    # earlier and silently diverged from the one actually being
    # built — every edit to it had no effect. Single source of
    # truth: aos-infra/entrypoint.sh only.
  mind/
    Ahankara/
      ahankara.jsonld          — immutable identity (never modified at runtime)
    Buddhi/
      buddhi.jsonld            — structured index
      philosophy.md            — occurrence model, four foundations, continuum
      organism.md              — the 15-repo ecosystem as one whole thing
      architecture.md          — key decisions and reasoning
      relationship.md          — how Architect and founder work together
      invariants.md            — what must never change and why
    Manas/
      context/
        company.jsonld         — ASI Saga company context (stable)
        boardroom.jsonld       — Boardroom product context (stable)
      content/
        active-work.jsonld     — current tasks and open items
        next-session.jsonld    — what to pick up at session start
    Possibility/
      possibility.md           — the declared future, network-scaled
    Integrity/
      integrity.jsonld         — commitment register (append-only)
    Responsibility/
      responsibility.md        — authorship stance
    Conversations/
      index.jsonld             — session index
      2026-06-07-session-9.md  — session 9 summary (most recent)
  whitepaper/
    README.md                  — whitepaper index
    01-declaration.md          — what the Boardroom is, in essence
    02-what-it-is.md           — the C-suite of agents, perpetual
    03-how-it-thinks.md        — occurrence, deliberation, resonance
    04-the-network.md          — organisations connected in resonance
    05-architecture.md         — the organism and its substrates
    06-the-genesis.md          — what ASI Saga is committed to
  skills/
    architect-claude/
      SKILL.md                 — what the Architect does (macro level)
      references/
        spec-format.md         — how to write specifications
        issue-template.md      — how to create issues for Copilot agents
    architect-copilot/
      SKILL.md                 — what the Copilot agent does in this repo
  modules/
    architect-container-app.bicep  — Container App definition
    architect-secrets.bicep        — Key Vault secrets
    architect-storage.bicep        — Azure Files share
  .github/
    repository.md              — repository specification
    specs/
      spec-architect-mind.md   — architect mind system design
    workflows/
      deploy-architect.yml     — pushes dynamic files to Azure Files share
```

---

## The two workflows

### `aos-infra` — builds the image

**`build-architect.yml`** — triggered when `Dockerfile.architect` or
`entrypoint.sh` changes in `aos-infra`. Builds the container image and
pushes to ACR. Runs rarely — only when the OS, Node.js, Claude Code
baseline, gh CLI, or the bootstrap script itself changes. Dispatches to
`architect-agent/deploy-architect.yml` on completion.

`entrypoint.sh` lives only here, at the `aos-infra` repo root — it is
baked into the image, never uploaded to the Azure Files share, and
never duplicated in `architect-agent`.

### `architect-agent` — deploys infrastructure and dynamic files

**`deploy-architect.yml`** — two jobs:

- `upload-dynamic-files`, triggered when any file in `container/`
  changes (except `entrypoint.sh`, which isn't here), or when
  dispatched by `aos-infra` after a new image build. Uploads
  `repos.txt`, `versions.env`, `CLAUDE.md`, `ARCHITECT-CONTEXT.md`, and
  `claude-settings.json` to the Azure Files share. No image rebuild. No
  Container App restart. Files take effect at next session start.

- `deploy-infrastructure`, triggered when `modules/*.bicep` changes
  here, or on the same dispatch. Deploys the Container App, the
  user-assigned identity, both role assignments, and the Key Vault
  secret. Always passes a fresh `revisionSuffix` (derived from the
  GitHub run number) so every deploy forces a genuinely new revision
  rather than silently no-op'ing against a stuck one.

---

## What triggers what

| Change | Workflow | Effect |
|---|---|---|
| `Dockerfile.architect` in `aos-infra` | `build-architect.yml` | Image rebuild → ACR push → dispatch deploy |
| `entrypoint.sh` in `aos-infra` | `build-architect.yml` | Image rebuild → ACR push → dispatch deploy |
| `modules/*.bicep` in `architect-agent` | `deploy-architect.yml` (`deploy-infrastructure` job) | Infrastructure deploy, new revision, no image rebuild |
| `versions.env` in `architect-agent` | `deploy-architect.yml` (`upload-dynamic-files` job) | File uploaded to Azure Files share |
| `CLAUDE.md` in `architect-agent` | `deploy-architect.yml` (`upload-dynamic-files` job) | File uploaded to Azure Files share |
| `repos.txt` in `architect-agent` | `deploy-architect.yml` (`upload-dynamic-files` job) | File uploaded to Azure Files share |
| `mind/` documents in `architect-agent` | none (read directly at runtime) | Available at next session start |
| Secrets rotation | `deploy-architect.yml` (`deploy-infrastructure` job) | Key Vault updated, no rebuild |

---

## Version management

`container/versions.env` declares the intended versions of Claude Code
and gh CLI:

```bash
CLAUDE_CODE_VERSION=1.x.x
GH_CLI_VERSION=2.x.x
NODE_VERSION=22
```

At session start, the baked-in `entrypoint.sh` (from `aos-infra`) reads
`versions.env` (cloned at runtime from `architect-agent`) and reports
installed vs declared. If a gap exists, it prints the update command.
The Architect (or the founder) decides when to trigger a rebuild in
`aos-infra`.

Updating `versions.env` in `architect-agent` records the intent. The
actual upgrade happens when `build-architect.yml` is manually triggered
in `aos-infra`, since `versions.env` only changes the Claude Code/gh CLI
versions Dockerfile.architect installs — it does not itself trigger a
rebuild (see the triggers table above; only `Dockerfile.architect` or
`entrypoint.sh` changing in `aos-infra` triggers `build-architect.yml`).

---

## Infrastructure (managed in `aos-infra`)

| Resource | Detail |
|---|---|
| Container App | `architect` in `cae-aos-staging` |
| Image | `acraosstagingerm2srfd.azurecr.io/aos/architect:latest` |
| Scale | min 0, max 1 (scale to zero when idle) |
| Ingress | Disabled — outbound only (Remote Control over HTTPS) |
| Storage | Azure Files `architect-home` mounted at `/root` |
| Secrets | Key Vault: `anthropic-api-key`, `architect-github-token` |
| Identity | System-assigned managed identity with AcrPull role |

---

## Connecting to the Architect

1. Open the Claude mobile app (or desktop)
2. Go to the **Code** tab
3. The architect session appears when the Container App is running

The Container App scales to zero when idle. The first connection cold-starts
it — allow ~30 seconds for the container to start and `entrypoint.sh` to
complete before the session is ready.

---

## Related repositories

| Repository | Relationship |
|---|---|
| `ASISaga/aos-infra` | Builds the image, deploys the infrastructure |
| `ASISaga/mind.asisaga.com` | MCP server — architect mind state at runtime |
| `ASISaga/agent-operating-system` | Meta-repo — architect-agent is the 16th submodule |
| All 15 ASISaga repositories | The ecosystem the Architect holds present |
