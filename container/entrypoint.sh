#!/bin/bash
set -euo pipefail

echo "=== AOS Architect — initialising ==="

# ---------------------------------------------------------------------
# 1. Claude Code settings
# ---------------------------------------------------------------------
mkdir -p ~/.claude
if [ ! -f ~/.claude/settings.json ]; then
  cp /opt/architect/claude-settings.json ~/.claude/settings.json
  echo "Installed Claude settings"
fi

# ---------------------------------------------------------------------
# 2. Session ground files
# ---------------------------------------------------------------------
cp /opt/architect/CLAUDE.md ~/CLAUDE.md
cp /opt/architect/ARCHITECT-CONTEXT.md ~/ARCHITECT-CONTEXT.md

# ---------------------------------------------------------------------
# 3. GitHub auth
# ---------------------------------------------------------------------
if [ -n "${ARCHITECT_GITHUB_TOKEN:-}" ]; then
  echo "${ARCHITECT_GITHUB_TOKEN}" | gh auth login --with-token
  gh auth setup-git
  echo "GitHub authenticated"
else
  echo "WARNING: ARCHITECT_GITHUB_TOKEN not set — gh CLI will not authenticate"
fi

# ---------------------------------------------------------------------
# 4. Clone the ecosystem (idempotent)
# ---------------------------------------------------------------------
mkdir -p ~/ASISaga
cd ~/ASISaga

REPOS=(
  agent-operating-system
  architect-agent
  purpose-agent
  leadership-agent
  ceo-agent
  cfo-agent
  cto-agent
  cso-agent
  cmo-agent
  aos-kernel
  aos-intelligence
  aos-infrastructure
  aos-dispatcher
  aos-realm-of-agents
  aos-mcp-servers
  aos-client-sdk
  business-infinity
  boardroom
  mind.asisaga.com
)

for repo in "${REPOS[@]}"; do
  if [ -d "$repo" ]; then
    echo "Updating $repo"
    (cd "$repo" && git fetch --quiet && git pull --quiet --ff-only) || \
      echo "  (skip — local changes or detached HEAD)"
  else
    echo "Cloning $repo"
    gh repo clone "ASISaga/$repo" "$repo" --quiet || \
      echo "  (skip — repo not found or inaccessible)"
  fi
done

# agent-operating-system carries submodules — sync them too
if [ -d agent-operating-system/.git ]; then
  (cd agent-operating-system && git submodule update --init --recursive --quiet) || true
fi

cd ~

# ---------------------------------------------------------------------
# 5. Start Claude Code with Remote Control
# ---------------------------------------------------------------------
echo "=== Starting Claude Code (Remote Control) ==="
exec claude --dangerously-skip-permissions --remote-control
