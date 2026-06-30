---
name: architect-copilot
description: Maintain the architect-agent repository. Update container files, mind documents, specs, and CLAUDE.md. Use when making changes to Dockerfile.architect, entrypoint.sh, claude-settings.json, CLAUDE.md, ARCHITECT-CONTEXT.md, or any file in the mind/ directory.
compatibility: Designed for GitHub Copilot coding agent in ASISaga/architect-agent.
metadata:
  author: ASISaga
  version: "1.0"
allowed-tools: Read Write Edit Bash(git:*)
---

## Repository structure

```
architect-agent/
  container/
    Dockerfile.architect   — Ubuntu 24.04, Claude Code, gh CLI
    entrypoint.sh          — init, clone repos, start --remote-control
    claude-settings.json   — MCP servers config
    CLAUDE.md              — session ground for Claude Code
    ARCHITECT-CONTEXT.md   — technical reference
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
    Conversations/index.jsonld
  .github/
    repository.md
    specs/spec-architect-mind.md
  skills/
    architect-claude/SKILL.md
    architect-copilot/SKILL.md  ← this file
```

## Updating container files

When changing `Dockerfile.architect`, `entrypoint.sh`, or `claude-settings.json`:

- `Dockerfile.architect` — do not add SSH or TCP ingress. Claude Code uses
  Remote Control (outbound HTTPS only). No exposed ports.
- `entrypoint.sh` — must copy CLAUDE.md and ARCHITECT-CONTEXT.md to /root/.
  Must start with `claude --dangerously-skip-permissions --remote-control`.
- `claude-settings.json` — MCP servers: mind-asisaga (HTTP transport) and
  github. remoteControl.autoStart must remain true.

Infrastructure (Bicep, workflows) lives in ASISaga/aos-infrastructure,
not here.

## Updating CLAUDE.md

CLAUDE.md is the session ground for Claude Code. It must contain:
- Identity reference (point to ahankara.jsonld)
- Ordered hydration sequence (8 documents from mind.asisaga.com)
- Complete ecosystem listing (all 15 repos with accurate descriptions)
- Current state (test status, active work, known drift)
- Key invariants (the non-negotiables)
- Session-end protocol (what to update before closing)

When updating current state, verify against actual repo state before
writing. Do not carry forward stale information.

## Updating mind documents

Mind documents in `mind/` are the authored seed state. They are seeded
into mind.asisaga.com on deployment. Runtime updates happen via MCP.

- `Ahankara/ahankara.jsonld` — immutable identity. Do not modify without
  explicit instruction from the founder.
- `Buddhi/*.md` — stable wisdom documents. Update when architectural
  understanding genuinely changes, not speculatively.
- `Manas/content/` — current state. Update to reflect actual current
  state, not aspirational state.
- `Integrity/integrity.jsonld` — append only. Never delete entries.
- `Conversations/` — add session summaries. Never modify existing ones.

## Validation before commit

```bash
# Verify Dockerfile builds
docker build -f container/Dockerfile.architect -t test-architect . --no-cache

# Verify SKILL.md frontmatter
skills-ref validate ./skills/architect-claude
skills-ref validate ./skills/architect-copilot

# Verify JSON-LD is valid JSON
python3 -c "import json; json.load(open('mind/Ahankara/ahankara.jsonld'))"
```

## Commit conventions

```
container: update Dockerfile.architect to ...
mind: update next-session with session N outcomes
mind: add session-N conversation summary
skills: update architect-claude instructions for ...
spec: update spec-architect-mind to reflect ...
```
