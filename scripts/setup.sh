#!/usr/bin/env bash
set -euo pipefail

echo "[SETUP] jimmBOT setup starting..."

# -------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

WS="${WORKSPACE_ROOT:-/workspaces}"
SRC_DIR="$WS/src"
META_DIR="$REPO_ROOT/.meta_workspaces"
META_SRC_DIR="$META_DIR/src"

REPOS_FILE="$REPO_ROOT/jimmbot.repos"

CLEAN_BUILD=false
if [ "${1:-}" = "clean" ]; then
  CLEAN_BUILD=true
fi

repo_names() {
  sed -n 's/^  \([a-zA-Z0-9_][a-zA-Z0-9_]*\):$/\1/p' "$REPOS_FILE"
}

# -------------------------------------------------------------------
# ROS setup
# -------------------------------------------------------------------
set +u
source /opt/ros/kilted/setup.bash
set -u

# -------------------------------------------------------------------
# Workspace validation
# -------------------------------------------------------------------
echo "[SETUP] Checking workspace: $WS"

mkdir -p "$SRC_DIR"
mkdir -p "$META_SRC_DIR"

# Keep the hidden host-persistent store out of colcon discovery.
touch "$META_DIR/COLCON_IGNORE"

if [ ! -w "$WS" ]; then
  echo "[SETUP][ERROR] Workspace is not writable: $WS"
  echo "Fix: sudo chown -R \$(whoami) $WS"
  exit 1
fi

if [ ! -f "$REPOS_FILE" ]; then
  echo "[SETUP][ERROR] Missing repos file: $REPOS_FILE"
  exit 1
fi

# -------------------------------------------------------------------
# SSH diagnostics (no hardcoding)
# -------------------------------------------------------------------
echo "[SETUP] SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-unset}"

# -------------------------------------------------------------------
# Clean mode
# -------------------------------------------------------------------
if [ "$CLEAN_BUILD" = true ]; then
  echo "[SETUP] Clean setup requested, refreshing managed workspace links"
  while read -r repo; do
    if [ -n "$repo" ] && [ "$repo" != "jimmbot_robot" ]; then
      rm -f "$SRC_DIR/$repo"
    fi
  done < <(repo_names)

  rm -f "$WS/.vscode" "$WS/build" "$WS/install" "$WS/log"
fi

workspace_vscode_target="$WS/.vscode"

if [ -e "$workspace_vscode_target" ] && [ ! -L "$workspace_vscode_target" ]; then
  echo "[SETUP][ERROR] Refusing to replace non-symlink path: $workspace_vscode_target"
  exit 1
fi

ln -sfn "$REPO_ROOT/.vscode" "$workspace_vscode_target"

# -------------------------------------------------------------------
# Persist generated workspace directories on the host.
# -------------------------------------------------------------------
for workspace_dir in build install log; do
  meta_target="$META_DIR/$workspace_dir"
  workspace_target="$WS/$workspace_dir"

  mkdir -p "$meta_target"

  if [ -e "$workspace_target" ] && [ ! -L "$workspace_target" ]; then
    echo "[SETUP] Preserving existing $workspace_dir into hidden workspace store"
    rm -rf "$meta_target"
    mv "$workspace_target" "$meta_target"
  fi

  ln -sfn "$meta_target" "$workspace_target"
done

# -------------------------------------------------------------------
# Detect missing repositories and refresh source symlinks.
# -------------------------------------------------------------------
echo "[SETUP] Checking repository state..."

MISSING=0

while read -r repo; do
  if [ -z "$repo" ]; then
    continue
  fi

  if [ "$repo" = "jimmbot_robot" ]; then
    continue
  fi

  if [ ! -d "$META_SRC_DIR/$repo" ]; then
    echo "[SETUP] Missing repo: $repo"
    MISSING=1
  fi

done < <(repo_names)

# -------------------------------------------------------------------
# Import repositories
# -------------------------------------------------------------------
if [ "$MISSING" -eq 1 ]; then
  echo "[SETUP] Running vcs import..."
  vcs import "$META_SRC_DIR" < "$REPOS_FILE"
else
  echo "[SETUP] All repos present, skipping import"
fi

while read -r repo; do
  if [ -z "$repo" ] || [ "$repo" = "jimmbot_robot" ]; then
    continue
  fi

  repo_source="$META_SRC_DIR/$repo"
  repo_link="$SRC_DIR/$repo"

  if [ ! -d "$repo_source" ]; then
    echo "[SETUP][ERROR] Expected repo missing after import: $repo_source"
    exit 1
  fi

  if [ -e "$repo_link" ] && [ ! -L "$repo_link" ]; then
    echo "[SETUP][ERROR] Refusing to replace non-symlink path: $repo_link"
    exit 1
  fi

  ln -sfn "$repo_source" "$repo_link"
done < <(repo_names)

# -------------------------------------------------------------------
# Shell sourcing
# -------------------------------------------------------------------
SETUP_LINE="source $WS/install/setup.bash"

if [ -f "$WS/install/setup.bash" ]; then
  if ! grep -Fxq "$SETUP_LINE" "$HOME/.bashrc"; then
    echo "$SETUP_LINE" >> "$HOME/.bashrc"
    echo "[SETUP] Added workspace sourcing to .bashrc"
  fi
fi

echo "[SETUP] Done."