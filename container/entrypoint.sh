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
# 4. Clone / update the ecosystem
#
# Repo list lives in repos.txt (one repo name per line, under ASISaga/).
# Each repo is either cloned fresh, or — if it already exists — updated
# only when it is safe to do so: clean working tree, on a branch
# (not detached HEAD), and no commits ahead of upstream. Anything else
# is left untouched and reported, never silently overwritten or skipped
# without explanation.
# ---------------------------------------------------------------------
mkdir -p ~/ASISaga
cd ~/ASISaga

while IFS= read -r repo; do
  [ -z "$repo" ] && continue

  if [ ! -d "$repo" ]; then
    echo "Cloning $repo"
    gh repo clone "ASISaga/$repo" "$repo" --quiet || \
      echo "  FAILED to clone $repo (not found or inaccessible)"
    continue
  fi

  if [ ! -d "$repo/.git" ]; then
    echo "  $repo exists but is not a git repo — leaving as-is"
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
      echo "  $repo: uncommitted local changes — leaving as-is"
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
done < /opt/architect/repos.txt

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
