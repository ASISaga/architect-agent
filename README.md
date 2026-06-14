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

---

## How a generic Claude Code becomes the Architect

### The image (owned by `aos-infra`)

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

### The Azure Files share (`/root`)

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

### The session ground (`CLAUDE.md`)

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

### The mind (`mind/`)

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

---

## Repository structure

```
architect-agent/
  README.md                         ← this file
  container/
    entrypoint.sh                   ← startup script (pushed to Azure Files)
    repos.txt                       ← ecosystem repo list (pushed to Azure Files)
    versions.env                    ← declared tool versions (pushed to Azure Files)
    CLAUDE.md                       ← session ground (pushed to Azure Files)
    ARCHITECT-CONTEXT.md            ← technical reference (pushed to Azure Files)
    claude-settings.json            ← MCP server config (pushed to Azure Files)
  mind/
    Ahankara/ahankara.jsonld
    Buddhi/
      buddhi.jsonld
      philosophy.md
      organism.md
      architecture.md
      relationship.md
      invariants.md
    Manas/
      context/company.jsonld
      context/boardroom.jsonld
      content/active-work.jsonld
      content/next-session.jsonld
    Possibility/possibility.md
    Integrity/integrity.jsonld
    Responsibility/responsibility.md
    Conversations/
      index.jsonld
      2026-06-07-session-9.md
  whitepaper/
    README.md
    01-declaration.md
    02-what-it-is.md
    03-how-it-thinks.md
    04-the-network.md
    05-architecture.md
    06-the-genesis.md
  skills/
    architect-claude/
      SKILL.md
      references/
        spec-format.md
        issue-template.md
    architect-copilot/
      SKILL.md
  modules/
    architect-container-app.bicep   ← Container App definition
    architect-secrets.bicep         ← Key Vault secrets
  .github/
    repository.md                   ← repository specification
    specs/
      spec-architect-mind.md
    workflows/
      deploy-architect.yml          ← pushes dynamic files + deploys Bicep
```

---

## What triggers what

| Change | Action | Rebuild? |
|---|---|---|
| `Dockerfile.architect` in `aos-infra` | `build-architect.yml` in `aos-infra` | Full image rebuild |
| `container/entrypoint.sh` | `deploy-architect.yml` → upload to Azure Files | No |
| `container/repos.txt` | `deploy-architect.yml` → upload to Azure Files | No |
| `container/versions.env` | `deploy-architect.yml` → upload to Azure Files | No |
| `container/CLAUDE.md` | `deploy-architect.yml` → upload to Azure Files | No |
| `container/ARCHITECT-CONTEXT.md` | `deploy-architect.yml` → upload to Azure Files | No |
| `container/claude-settings.json` | `deploy-architect.yml` → upload to Azure Files | No |
| `modules/architect-container-app.bicep` | `deploy-architect.yml` → Bicep deploy | No |
| `modules/architect-secrets.bicep` | `deploy-architect.yml` → Bicep deploy | No |
| `mind/**` | Commit only — seeded to `mind.asisaga.com` separately | No |
| `whitepaper/**` | Commit only — available to architect via clone | No |

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

## Related repositories

| Repository | Relationship |
|---|---|
| `ASISaga/aos-infra` | Owns the Docker image and build workflow |
| `ASISaga/mind.asisaga.com` | MCP server — mind state at runtime |
| `ASISaga/agent-operating-system` | Meta-repo — 16th submodule |
| All 15 ASISaga repositories | The ecosystem the architect holds present |
