#!/usr/bin/env bash
set -euo pipefail

echo "[BOOTSTRAP] jimmBOT setup starting..."

# -------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

WS="${WORKSPACE_ROOT:-/workspaces}"
SRC_DIR="$WS/src"
MARKER="$WS/.bootstrap_done"

REPOS_FILE="$REPO_ROOT/jimmbot.repos"

CLEAN_BUILD=false
if [ "${1:-}" = "clean" ]; then
  CLEAN_BUILD=true
fi

# -------------------------------------------------------------------
# ROS setup
# -------------------------------------------------------------------
set +u
source /opt/ros/kilted/setup.bash
set -u

# -------------------------------------------------------------------
# Workspace validation
# -------------------------------------------------------------------
echo "[BOOTSTRAP] Checking workspace: $WS"

mkdir -p "$SRC_DIR"

if [ ! -w "$WS" ]; then
  echo "[BOOTSTRAP][ERROR] Workspace is not writable: $WS"
  echo "Fix: sudo chown -R \$(whoami) $WS"
  exit 1
fi

if [ ! -f "$REPOS_FILE" ]; then
  echo "[BOOTSTRAP][ERROR] Missing repos file: $REPOS_FILE"
  exit 1
fi

# -------------------------------------------------------------------
# SSH diagnostics (no hardcoding)
# -------------------------------------------------------------------
echo "[BOOTSTRAP] SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-unset}"

# -------------------------------------------------------------------
# Clean mode
# -------------------------------------------------------------------
if [ "$CLEAN_BUILD" = true ]; then
  echo "[BOOTSTRAP] Clean rebuild requested"
  rm -rf "$WS/build" "$WS/install" "$WS/log" "$MARKER"
fi

# -------------------------------------------------------------------
# Detect missing repositories (correct logic)
# -------------------------------------------------------------------
echo "[BOOTSTRAP] Checking repository state..."

MISSING=0

while read -r line; do
  repo=$(echo "$line" | awk '{print $1}')

  # skip invalid lines
  if [ -z "$repo" ]; then
    continue
  fi

  # skip internal repo
  if [ "$repo" = "jimmbot_robot" ]; then
    continue
  fi

  if [ ! -d "$SRC_DIR/$repo" ]; then
    echo "[BOOTSTRAP] Missing repo: $repo"
    MISSING=1
  fi

done < <(grep -E "^[ ]{2}[a-zA-Z0-9_]+" "$REPOS_FILE")

# -------------------------------------------------------------------
# Import repositories
# -------------------------------------------------------------------
if [ "$MISSING" -eq 1 ]; then
  echo "[BOOTSTRAP] Running vcs import..."
  vcs import "$SRC_DIR" < "$REPOS_FILE"
else
  echo "[BOOTSTRAP] All repos present, skipping import"
fi

# -------------------------------------------------------------------
# Mark completed
# -------------------------------------------------------------------
touch "$MARKER"

# -------------------------------------------------------------------
# Shell sourcing
# -------------------------------------------------------------------
SETUP_LINE="source $WS/install/setup.bash"

if [ -f "$WS/install/setup.bash" ]; then
  if ! grep -Fxq "$SETUP_LINE" "$HOME/.bashrc"; then
    echo "$SETUP_LINE" >> "$HOME/.bashrc"
    echo "[BOOTSTRAP] Added workspace sourcing to .bashrc"
  fi
fi

echo "[BOOTSTRAP] Done."