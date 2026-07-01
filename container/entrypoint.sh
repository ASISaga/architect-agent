#!/bin/bash
set -euo pipefail

echo "=== AOS Architect — initialising ==="

# ---------------------------------------------------------------------
# 1. GitHub auth
# ---------------------------------------------------------------------
if [ -n "${ARCHITECT_GITHUB_TOKEN:-}" ]; then
  echo "${ARCHITECT_GITHUB_TOKEN}" | gh auth login --with-token
  gh auth setup-git
  echo "GitHub: authenticated"
else
  echo "WARNING: ARCHITECT_GITHUB_TOKEN not set — gh CLI will not authenticate"
fi

# ---------------------------------------------------------------------
# 2. Bootstrap — clone architect-agent if not present
#    This is the one hardcoded repo. All other config flows from it.
# ---------------------------------------------------------------------
mkdir -p ~/ASISaga
cd ~/ASISaga

if [ ! -d architect-agent ]; then
  echo "Cloning architect-agent (bootstrap)"
  gh repo clone ASISaga/architect-agent architect-agent
else
  echo "architect-agent: present"
fi

CONTAINER_DIR=~/ASISaga/architect-agent/container

# ---------------------------------------------------------------------
# 3. Runtime configuration — always read from architect-agent clone,
#    never baked into the image
# ---------------------------------------------------------------------
mkdir -p ~/.claude
cp "$CONTAINER_DIR/claude-settings.json" ~/.claude/settings.json
cp "$CONTAINER_DIR/CLAUDE.md" ~/CLAUDE.md
cp "$CONTAINER_DIR/ARCHITECT-CONTEXT.md" ~/ARCHITECT-CONTEXT.md

# ---------------------------------------------------------------------
# 4. Clone / update ecosystem repos from repos.txt
#
# Each repo is handled safely:
# - Clean + behind upstream → fast-forward merge
# - Uncommitted changes → leave as-is, report
# - Unpushed commits → leave as-is, report
# - Detached HEAD → leave as-is, report
# Nothing is ever silently overwritten or lost.
# ---------------------------------------------------------------------
echo ""
echo "=== Ecosystem sync ==="

while IFS= read -r repo; do
  [ -z "$repo" ] && continue
  [ "$repo" = "architect-agent" ] && continue  # already handled above

  if [ ! -d "$repo" ]; then
    echo "Cloning $repo"
    gh repo clone "ASISaga/$repo" "$repo" || \
      echo "  FAILED — not found or inaccessible"
    continue
  fi

  if [ ! -d "$repo/.git" ]; then
    echo "  $repo: not a git repo — leaving as-is"
    continue
  fi

  (
    cd "$repo"

    branch="$(git symbolic-ref --short -q HEAD || true)"
    if [ -z "$branch" ]; then
      echo "  $repo: detached HEAD — leaving as-is"
      exit 0
    fi

    if [ -n "$(git status --porcelain)" ]; then
      echo "  $repo: uncommitted changes — leaving as-is"
      exit 0
    fi

    git fetch --quiet

    ahead="$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)"
    if [ "$ahead" != "0" ]; then
      echo "  $repo: $ahead unpushed commit(s) on $branch — leaving as-is"
      exit 0
    fi

    behind="$(git rev-list --count "HEAD..@{u}" 2>/dev/null || echo 0)"
    if [ "$behind" = "0" ]; then
      echo "  $repo: up to date"
    else
      git merge --ff-only "@{u}" --quiet
      echo "  $repo: updated ($behind commit(s))"
    fi
  )
done < "$CONTAINER_DIR/repos.txt"

# Sync submodules of agent-operating-system
if [ -d agent-operating-system/.git ]; then
  (cd agent-operating-system && \
    git submodule update --init --recursive --quiet) || true
fi

cd ~

# ---------------------------------------------------------------------
# 5. Version report — check, never auto-install
#    Reads declared versions from versions.env; compares to installed.
#    Update commands are printed if a gap exists — you decide when.
# ---------------------------------------------------------------------
echo ""
echo "=== Version report ==="

# shellcheck source=/dev/null
source "$CONTAINER_DIR/versions.env"

# Claude Code
CLAUDE_INSTALLED="$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo 'unknown')"
echo "Claude Code: installed=$CLAUDE_INSTALLED  declared=$CLAUDE_CODE_VERSION"
if [ "$CLAUDE_INSTALLED" != "$CLAUDE_CODE_VERSION" ]; then
  echo "  → Gap detected. To upgrade: trigger build-architect.yml in aos-infra"
  echo "    after updating CLAUDE_CODE_VERSION in container/versions.env"
fi

# gh CLI
GH_INSTALLED="$(gh --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || echo 'unknown')"
echo "gh CLI:      installed=$GH_INSTALLED  declared=$GH_CLI_VERSION"
if [ "$GH_INSTALLED" != "$GH_CLI_VERSION" ]; then
  echo "  → Gap detected. To upgrade: trigger build-architect.yml in aos-infra"
  echo "    after updating GH_CLI_VERSION in container/versions.env"
fi

# Node.js
NODE_INSTALLED="$(node --version 2>/dev/null | sed 's/^v//' || echo 'unknown')"
echo "Node.js:     installed=$NODE_INSTALLED  declared=$NODE_VERSION.x"

echo ""

# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# 6. Claude Code auth check
# Credentials persist in ~/.claude/ on the Azure Files share.
# On first start: run 'claude login' in the terminal after connecting.
# Subsequent starts: already authenticated from persisted credentials.
# ---------------------------------------------------------------------
if [ ! -f ~/.claude/credentials.json ]; then
  echo "NOTE: Claude Code not yet authenticated."
  echo "      After connecting via Remote Control, run: claude login"
  echo "      Credentials will persist to the Azure Files share."
else
  echo "Claude Code: authenticated"
fi

# ---------------------------------------------------------------------
# 7. Test hook — if a test script was uploaded to the share, run it
#    and exit instead of starting Claude Code. The workflow that
#    uploaded the script reads the output from container console logs.
#    This enables TTY-free container inspection from GitHub Actions
#    without needing a local terminal or the mobile app.
# ---------------------------------------------------------------------
if [ -f /root/architect-test.sh ]; then
  echo "=== Test script found — running diagnostic mode ==="
  bash /root/architect-test.sh
  echo "=== Diagnostic complete — exiting ==="
  exit 0
fi

# ---------------------------------------------------------------------
# 8. Start Claude Code with Remote Control
#    Run as a child process (not exec) so the entrypoint stays alive
#    as PID 1, keeping the container accessible via exec at any time.
# ---------------------------------------------------------------------
echo "=== Starting Claude Code (Remote Control) ==="
claude --dangerously-skip-permissions --remote-control &
CLAUDE_PID=$!
echo "Claude Code started (PID $CLAUDE_PID)"
wait $CLAUDE_PID
echo "Claude Code exited (PID $CLAUDE_PID)"
