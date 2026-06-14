# architect-agent

The source repository for the AOS Architect — Claude Code running natively
in an Azure Container App, deeply hydrated in the ASI Saga ecosystem,
operating as the architect of the Agent Operating System.

---

## What this repository is

Every other agent in the AOS ecosystem has a dedicated source repository.
The architect is no different. This repository holds everything that
transforms a generic Claude Code instance into the ASI Saga Architect:

- The architect's mind — identity, accumulated wisdom, current state
- The container runtime configuration — scripts and settings
- The infrastructure definition — Bicep modules and deployment workflow
- The whitepaper — the foundation document the architect develops
- The skills — operating instructions for the architect and its Copilot agent

What this repository does not hold: the Docker image, the OS tooling, the
baseline installation of Claude Code and gh CLI. Those are infrastructure
concerns owned by `ASISaga/aos-infra`. This repository owns everything that
makes the architect *this particular architect*, not just a capable tool.

architect-agent is the identity, mind, and dynamic configuration of
the Architect. It does not contain the infrastructure that runs it
(that lives in ASISaga/aos-infra) — it contains everything that makes
a generic Claude Code instance become the Architect of ASI Saga.

The distinction is precise: aos-infra builds and deploys the container.
architect-agent defines who lives inside it.
---

## How a generic Claude Code becomes the Architect

### Layer 1 — The environment (from aos-infra)

The Docker image at `acraosstagingerm2srfd.azurecr.io/aos/architect:latest`
contains only stable, rarely-changing layers:

- Ubuntu 24.04 base
- Node.js
- Claude Code (baseline version)
- gh CLI

The image has no knowledge of ASI Saga. It is a capable but generic
Claude Code runtime. Its entrypoint is a single line:

```dockerfile
CMD ["/bin/bash", "-c", "exec /root/entrypoint.sh"]
```

It executes whatever `entrypoint.sh` it finds on the Azure Files share
at `/root`. The image itself never needs to change unless the OS or
baseline tooling versions change.

The container image provides the runtime environment: Ubuntu 24.04,
Node.js, Claude Code at its baseline version, and the GitHub CLI.
This layer is stable and rarely changes. It is not what makes Claude Code
the Architect — it is the substrate the Architect runs on.

### Layer 2 — The bootstrap (from the Azure Files share) (`/root`)

The Azure Files share `architect-home` is mounted at `/root` in the
Container App. It persists across container restarts and sessions. It holds
all the dynamic files that constitute the architect's runtime environment:

```
/root/
  entrypoint.sh          ← startup script
  repos.txt              ← list of ASISaga repos to clone/update
  versions.env           ← declared versions of Claude Code and gh CLI
  CLAUDE.md              ← session ground: identity, ecosystem, current state
  ARCHITECT-CONTEXT.md   ← technical reference: SDK state, patterns, drift
  ASISaga/               ← all cloned repos, persisted across sessions
  .claude/               ← Claude Code settings and session state
```

These files are managed by this repository and pushed to the share by the
`deploy-architect.yml` workflow. Updating any of them requires no image
rebuild and no Container App restart — they are read fresh at every
container start.

When the container starts, it executes /root/entrypoint.sh — the first
file read from the Azure Files share. This script:


Authenticates with GitHub
Clones architect-agent itself (the bootstrap repo)
Reads repos.txt and clones or updates all 19 ASISaga repositories
Copies CLAUDE.md and ARCHITECT-CONTEXT.md to ~/
Reads versions.env and reports installed vs declared versions
Starts Claude Code with Remote Control


The Azure Files share persists across container restarts — so cloned
repositories, accumulated session state, and .claude/ settings survive
scale-to-zero cycles.

### The startup sequence (`entrypoint.sh`)

When the Container App starts, `entrypoint.sh` runs. This is where the
transformation from generic Claude Code to ASI Saga Architect happens:

**1. GitHub authentication**
The GitHub PAT from Key Vault is used to authenticate `gh` CLI, giving
the architect access to all ASISaga repositories.

**2. Bootstrap**
`architect-agent` is cloned into `~/ASISaga/architect-agent` if not
already present. This is the one hardcoded repository — everything else
flows from it.

**3. Runtime configuration**
`CLAUDE.md` and `ARCHITECT-CONTEXT.md` are copied to `~/`. Claude Code
reads `CLAUDE.md` automatically at session start. `claude-settings.json`
is installed, connecting Claude Code to `mind.asisaga.com` via MCP.

**4. Ecosystem clone**
All repositories listed in `repos.txt` are cloned or safely updated.
Safe update means: only fast-forward, only if the working tree is clean,
only if there are no unpushed commits. Any unsafe state is reported
clearly, never silently overwritten.

**5. Version report**
The installed versions of Claude Code and gh CLI are compared against the
declared versions in `versions.env`. If a newer version is available, the
update command is printed. The architect decides when to update — nothing
is auto-installed.

**6. Claude Code starts**
`exec claude --dangerously-skip-permissions --remote-control`
Claude Code starts with Remote Control enabled. The founder connects via
the Claude mobile app → Code tab. The architect is available.

### Layer 3 — The session ground (from container/)

Before any task, Claude Code reads two files placed at ~/ by the
entrypoint:

CLAUDE.md — the session ground. Who the Architect is, what to
read from mind.asisaga.com before any task, the full ecosystem map,
current state of the work, key invariants, and the session-end protocol.
This is the first document Claude Code reads in every session. It is
the difference between a capable tool and a grounded participant.

ARCHITECT-CONTEXT.md — the technical reference. SDK versions,
the one failing test and its fix, pipeline patterns, Foundry registration,
the drift table, ERPNext phases, session history. Everything a human
member of the team would know from having been present across the nine
sessions that built this system.

`CLAUDE.md` is the first thing Claude Code reads in every session. It
holds:

- The architect's identity and operating level
- The ordered hydration sequence from `mind.asisaga.com`
- The complete ecosystem map — all 15 repositories, their roles and state
- Current active work and known drift
- The key architectural invariants
- The session-end protocol

Without `CLAUDE.md`, Claude Code is capable but generic. With it, Claude
Code arrives at the work already knowing the organism, the decisions, the
current state, and what needs to happen next.

### Layer 4 — The mind (from mind/ via mind.asisaga.com)

The deepest layer. Before any task, the Architect reads its mind
documents from mind.asisaga.com via MCP — or, if the MCP connection
is unavailable, from the local clone at ~/ASISaga/architect-agent/mind/.

The architect's mind documents are the accumulated wisdom of nine sessions
of architectural work. They are seeded into `mind.asisaga.com` on
deployment and persist in Azure Tables between sessions. They hold:

```
mind/
  Ahankara/          ← immutable identity — who the architect is
  Buddhi/            ← stable discriminating intelligence
    philosophy.md    ← occurrence model, four foundations, the continuum
    organism.md      ← the 15-repo ecosystem as one whole thing
    architecture.md  ← key decisions and the reasoning behind them
    relationship.md  ← how the architect and founder work together
    invariants.md    ← what must never change and why
  Manas/
    context/         ← stable company and product context
    content/         ← current working reality, updated each session
  Possibility/       ← the declared future — network of organisations
  Integrity/         ← commitment register, append-only
  Responsibility/    ← authorship stance
  Conversations/     ← session history, indexed
```

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

Together, through these documents the Chitta of the Architect — the
awareness substrate within which it operates, finds its expression into the workd.
Reading them at session start is not optional. It is what makes each new session continuous with
all that came before.

**Chitta** — the universal ground shared across all agents — is owned by
`mind.asisaga.com` itself, not by this repository. The architect reads it
via MCP; it is not replicated here.

The distinction between mind layers:

- **Ahankara** — immutable. Never updated during operation.
- **Buddhi** — stable. Updated when architectural understanding genuinely
  shifts, not session by session.
- **Manas/context** — stable company and product context. Rarely changes.
- **Manas/content** — current reality. Updated every session.
- **Integrity** — append-only. Commitments are added, never deleted.
- **Conversations** — new session summaries added. Existing ones never
  modified.

## Repository structure

```
architect-agent/
  README.md                    — this file
  container/
    entrypoint.sh              — bootstrap script (runs at container start)
    repos.txt                  — list of ASISaga repos to clone/update
    versions.env               — declared versions of Claude Code, gh CLI
    CLAUDE.md                  — session ground (read by Claude Code first)
    ARCHITECT-CONTEXT.md       — technical reference
    claude-settings.json       — MCP servers, Remote Control config
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

      
### The whitepaper (`whitepaper/`)

The foundation document for the definitive ASI Saga whitepaper. Six
sections, whole and complete in itself, with the network vision — a global
network of organisations connected in resonance — at its heart.

The architect's first major task is to develop this foundation into the
definitive whitepaper: deepening each section, adding concrete detail,
fully visualising the network effects across industries and value chains.

### The skills (`skills/`)

```
skills/
  architect-claude/    ← operating instructions for Claude Code as architect
    SKILL.md           ← what the architect does and how
    references/        ← spec format guide, issue template
  architect-copilot/   ← operating instructions for the Copilot coding agent
    SKILL.md           ← how to maintain this repository
```

Two skills because two agents operate in this repository:
- Claude Code (the architect runtime) reads `architect-claude/SKILL.md`
- GitHub Copilot (the coding agent) reads `architect-copilot/SKILL.md`

### The two workflows

aos-infra — builds and deploys infrastructure

build-architect.yml — triggered when Dockerfile.architect changes
in aos-infra. Builds the container image and pushes to ACR. Runs rarely
— only when the OS, Node.js, Claude Code baseline, or gh CLI changes.
Dispatches to architect-agent/deploy-architect.yml on completion.

deploy-architect-infra.yml — triggered when Bicep modules change
in aos-infra. Deploys the Container App, Key Vault secrets, and Azure
Files share. No image rebuild.

architect-agent — manages dynamic files

deploy-architect.yml — triggered when any file in container/
changes, or when dispatched by aos-infra after a new image build.
Uploads entrypoint.sh, repos.txt, versions.env, CLAUDE.md,
ARCHITECT-CONTEXT.md, and claude-settings.json to the Azure Files
share. No image rebuild. No Container App restart. Files take effect
at next session start.

---

## What triggers what

| Change | Action Workflow | Effect |
|---|---|---|
| `Dockerfile.architect` in `aos-infra` | `build-architect.yml` in `aos-infra` | Image rebuild → ACR push → dispatch deploy |
| Bicep modules in `aos-infra` | `deploy-architect-infra.yml` | Infrastructure deploy, no rebuild |
| `entrypoint.sh` in `architect-agent` | `deploy-architect.yml` | File uploaded to Azure Files share |
| `repos.txt` in `architect-agent` | `deploy-architect.yml` | File uploaded to Azure Files share |
| `versions.env` in `architect-agent` | `deploy-architect.yml` | File uploaded to Azure Files share |
| `CLAUDE.md` in `architect-agent` | `deploy-architect.yml` | File uploaded to Azure Files share |
| `container/ARCHITECT-CONTEXT.md` | `deploy-architect.yml` → upload to Azure Files | No |
| `container/claude-settings.json` | `deploy-architect.yml` → upload to Azure Files | No |
| `modules/architect-container-app.bicep` | `deploy-architect.yml` → Bicep deploy | No |
| `modules/architect-secrets.bicep` | `deploy-architect.yml` → Bicep deploy | No |
| `mind/` documents in `architect-agent` | none (read directly at runtime) | Available at next session start |
| `whitepaper/**` | Commit only — available to architect via clone | No |
| Secrets rotation | `deploy-architect.yml` | Key Vault updated, no rebuild |

---

## What lives where

| Concern | Repository |
|---|---|
| Docker image (OS, Node.js, Claude Code, gh CLI) | `ASISaga/aos-infra` |
| Image build workflow | `ASISaga/aos-infra` |
| Dynamic runtime files | `ASISaga/architect-agent/container/` |
| Bicep modules | `ASISaga/architect-agent/modules/` |
| Deploy workflow | `ASISaga/architect-agent/.github/workflows/` |
| Architect mind | `ASISaga/architect-agent/mind/` |
| Mind runtime state | `mind.asisaga.com` Azure Tables |
| Whitepaper | `ASISaga/architect-agent/whitepaper/` |
| Skills | `ASISaga/architect-agent/skills/` |

---

## Version management

`container/versions.env` declares the intended versions of Claude Code
and gh CLI:

```bash
CLAUDE_CODE_VERSION=1.x.x
GH_CLI_VERSION=2.x.x
NODE_VERSION=22
```

At session start, `entrypoint.sh` reads this file and reports installed
vs declared. If a gap exists, it prints the update command. The Architect
(or the founder) decides when to trigger a rebuild in `aos-infra`.

Updating `versions.env` in `architect-agent` records the intent. The
actual upgrade happens when `build-architect.yml` is manually triggered
in `aos-infra`.

---

---

## Secrets required

| Secret | Where | Purpose |
|---|---|---|
| `ANTHROPIC_API_KEY` | `architect-agent` repo secrets | Claude Code authentication |
| `ARCHITECT_GITHUB_TOKEN` | `architect-agent` repo secrets | gh CLI git operations |
| `KEY_VAULT_NAME` | `architect-agent` repo secrets | Bicep deployment |
| `STORAGE_ACCOUNT_NAME` | `architect-agent` repo secrets | Azure Files upload |
| `AZURE_CLIENT_ID` | Org secrets (inherited) | OIDC auth |
| `AZURE_TENANT_ID` | Org secrets (inherited) | OIDC auth |
| `AZURE_SUBSCRIPTION_ID` | Org secrets (inherited) | OIDC auth |

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
