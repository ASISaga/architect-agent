#!/bin/bash
set -euo pipefail

echo "=== AOS Architect — initialising ==="

# ---------------------------------------------------------------------
# 1. GitHub auth
# TEMPORARY: auth failure is non-fatal — repos are already cloned on
# the persistent share, so a bad/expired token should not block Claude
# Code from starting. Revisit once the token is refreshed.
# ---------------------------------------------------------------------
if [ -n "${ARCHITECT_GITHUB_TOKEN:-}" ]; then
  if echo "${ARCHITECT_GITHUB_TOKEN}" | gh auth login --with-token 2>&1; then
    gh auth setup-git
    echo "GitHub: authenticated"
  else
    echo "WARNING: GitHub auth failed — continuing without it (repos already cloned)"
  fi
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
# 4. Clone / update ecosystem repos from ASISaga/.gitmodules
#
# .gitmodules is the authoritative repo list — maintained by the
# ecosystem root repository, not duplicated in a separate file.
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

# Parse submodule URLs from ASISaga/.gitmodules — the authoritative
# repo list at the workspace root. ASISaga is the root repository;
# all ecosystem repos are submodules within it. The bootstrap runs
# from ~/ASISaga/ so .gitmodules is in the current directory.
GITMODULES=".gitmodules"

if [ ! -f "$GITMODULES" ]; then
  echo "  WARNING: .gitmodules not found in $(pwd)"
  echo "  Expected the bootstrap to run from ~/ASISaga/ (the root repo)"
fi

if [ -f "$GITMODULES" ]; then
  REPOS=$(grep '^	*url' "$GITMODULES" | sed 's|.*github.com/ASISaga/||; s|\.git.*$||; s|[[:space:]]||g')
else
  REPOS=""
fi

for repo in $REPOS; do
  [ -z "$repo" ] && continue
  [ "$repo" = "architect-agent" ] && continue  # already handled above

  if [ ! -d "$repo" ]; then
    echo "  $repo: cloning"
    gh repo clone "ASISaga/$repo" "$repo" -- --recurse-submodules --quiet       || echo "  $repo: WARNING — clone failed, continuing"
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
      git submodule update --init --recursive --quiet || true
      echo "  $repo: updated ($behind commit(s))"
    fi
  ) || echo "  $repo: WARNING — sync failed, continuing"
done

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
# On first start: run 'claude login' via the Code tab after connecting,
# or via Cloud Shell: az containerapp exec ... --command /bin/bash
# then: claude login
# Subsequent starts: already authenticated from persisted credentials.
# ---------------------------------------------------------------------
if [ ! -f ~/.claude/.credentials.json ]; then
  echo "Claude Code: NOT authenticated — credentials.json absent"
  echo "      First-time setup required: run 'claude login' after connecting"
  echo "      NOTE: Remote Control may not accept connections until login is complete"
else
  echo "Claude Code: authenticated — credentials.json present"
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
#    Claude Code refuses --dangerously-skip-permissions as root.
#    Drop privileges to the 'architect' user just for the claude
#    process. runuser works without a TTY, unlike su.
#
#    If credentials are absent, Claude Code's --remote-control fails
#    fast (falls into --print mode expecting piped input, then exits).
#    That produces an unrecoverable crash-loop: the container never
#    stays alive long enough for `claude login` to be run interactively.
#
#    So: if unauthenticated, skip starting Claude Code entirely and
#    idle instead. This keeps the container alive indefinitely so it
#    can be exec'd into to run `claude login` once. After login
#    succeeds, restart the revision — this branch will no longer be
#    taken since credentials.json will be present.
# ---------------------------------------------------------------------
echo "=== Starting Claude Code (Remote Control) ==="

id architect &>/dev/null || useradd -m -s /bin/bash architect
chmod o+rx /root
chown -R architect:architect /root/.claude 2>/dev/null || true

if [ ! -f /root/.claude/.credentials.json ]; then
  echo ""
  echo "=== IDLING — Claude Code not authenticated ==="
  echo "Run 'claude login' via: az containerapp exec --name architect"
  echo "  --resource-group rg-aos-staging --command /bin/bash"
  echo "Then run: claude login"
  echo "Container will stay alive idling until then."
  echo ""
  sleep infinity
fi

CLAUDE_BIN=$(which claude)
runuser -u architect -- "$CLAUDE_BIN" --dangerously-skip-permissions --remote-control &
CLAUDE_PID=$!
echo "Claude Code started as 'architect' user (PID $CLAUDE_PID)"
wait $CLAUDE_PID
CLAUDE_EXIT=$?
echo "Claude Code exited (PID $CLAUDE_PID) with code $CLAUDE_EXIT"

# If Claude Code exited (for any reason — crash, --print fallback, etc.),
# don't let the container exit too. Idle instead so it stays exec-able
# for diagnosis rather than crash-looping indefinitely.
echo ""
echo "=== IDLING — Claude Code exited unexpectedly (code $CLAUDE_EXIT) ==="
echo "Container will stay alive for diagnosis via:"
echo "  az containerapp exec --name architect --resource-group rg-aos-staging --command /bin/bash"
echo ""
sleep infinity
