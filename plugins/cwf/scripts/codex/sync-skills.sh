#!/usr/bin/env bash
# sync-skills.sh: Link CWF skills into Codex scope-specific destinations.
#
# Why:
# - CWF is developed in-repo and updated frequently.
# - Symlinks let Codex load the latest local skill files without reinstallation.
#
# Usage:
#   plugins/cwf/scripts/codex/sync-skills.sh
#   plugins/cwf/scripts/codex/sync-skills.sh --dry-run
#
# Notes:
# - This script never uses rm. When replacing files/dirs, it moves them to backup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENTS_HOME="${AGENTS_HOME:-$HOME/.agents}"
DEST_SKILLS_DIR="$AGENTS_HOME/skills"
DEST_REFERENCES_PATH="$AGENTS_HOME/references"
SCOPE="${CWF_CLAUDE_PLUGIN_SCOPE:-user}"
PROJECT_ROOT=""

LINK_REFERENCES=true
DRY_RUN=false
VERIFY_LINKS=true

usage() {
  cat <<'EOF'
Sync CWF skills into Codex scope-specific paths via symlinks.

Usage:
  sync-skills.sh [options]

Options:
  --scope <user|project|local>
                        Integration scope (default: user)
  --project-root <path> Project root for project/local scope (default: git root or cwd)
  --repo-root <path>      Plugin root override (default: auto-detect from script location)
  --agents-home <path>    Agents home (default: ~/.agents or $AGENTS_HOME)
  --skills-dir <path>     Destination skills dir (overrides --agents-home)
  --no-references         Do not link ~/.agents/references
  --no-verify             Skip post-sync reference validation
  --dry-run               Print actions without modifying files
  -h, --help              Show this help
EOF
}

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

backup_path_for() {
  local root="$1"
  local name="$2"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  printf '%s/%s-%s' "$root" "$name" "$stamp"
}

safe_replace_with_symlink() {
  local source_path="$1"
  local link_path="$2"
  local backup_root="$3"

  run_cmd mkdir -p "$(dirname "$link_path")"

  if [[ -e "$link_path" && ! -L "$link_path" ]]; then
    run_cmd mkdir -p "$backup_root"
    local backup_target
    backup_target="$(backup_path_for "$backup_root" "$(basename "$link_path")")"
    run_cmd mv "$link_path" "$backup_target"
    echo "Moved existing path to backup: $backup_target"
  fi

  run_cmd ln -sfn "$source_path" "$link_path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      SCOPE="${2:-}"
      shift 2
      ;;
    --project-root)
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    --repo-root)
      PLUGIN_ROOT="${2:-}"
      shift 2
      ;;
    --agents-home)
      AGENTS_HOME="${2:-}"
      DEST_SKILLS_DIR="$AGENTS_HOME/skills"
      DEST_REFERENCES_PATH="$AGENTS_HOME/references"
      shift 2
      ;;
    --skills-dir)
      DEST_SKILLS_DIR="${2:-}"
      shift 2
      ;;
    --no-references)
      LINK_REFERENCES=false
      shift
      ;;
    --no-verify)
      VERIFY_LINKS=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$SCOPE" in
  user|project|local) ;;
  *)
    echo "Invalid scope: $SCOPE (allowed: user|project|local)" >&2
    exit 1
    ;;
esac

if [[ "$SCOPE" == "project" || "$SCOPE" == "local" ]]; then
  if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")"
  fi
  if [[ ! -d "$PROJECT_ROOT" ]]; then
    echo "Project root not found: $PROJECT_ROOT" >&2
    exit 1
  fi
  PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
  DEST_SKILLS_DIR="$PROJECT_ROOT/.codex/skills"
  DEST_REFERENCES_PATH="$PROJECT_ROOT/.codex/references"
  BACKUP_BASE="$PROJECT_ROOT/.codex/.skill-sync-backup"
else
  BACKUP_BASE="$AGENTS_HOME/.skill-sync-backup"
fi

SOURCE_SKILLS_DIR="$PLUGIN_ROOT/skills"
SOURCE_REFERENCES_DIR="$PLUGIN_ROOT/references"
SCRIPT_ROOT="$PLUGIN_ROOT/scripts"

if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
  echo "Source skills directory not found: $SOURCE_SKILLS_DIR" >&2
  exit 1
fi

if [[ "$LINK_REFERENCES" == "true" && ! -d "$SOURCE_REFERENCES_DIR" ]]; then
  echo "Source references directory not found: $SOURCE_REFERENCES_DIR" >&2
  exit 1
fi

run_cmd mkdir -p "$DEST_SKILLS_DIR"

linked_count=0
for skill_dir in "$SOURCE_SKILLS_DIR"/*; do
  [[ -d "$skill_dir" ]] || continue
  [[ -f "$skill_dir/SKILL.md" ]] || continue

  skill_name="$(basename "$skill_dir")"
  link_path="$DEST_SKILLS_DIR/$skill_name"
  safe_replace_with_symlink "$skill_dir" "$link_path" "$BACKUP_BASE"
  linked_count=$((linked_count + 1))
  echo "Linked skill: $skill_name"
done

if [[ "$LINK_REFERENCES" == "true" ]]; then
  safe_replace_with_symlink "$SOURCE_REFERENCES_DIR" "$DEST_REFERENCES_PATH" "$BACKUP_BASE"
  echo "Linked references: $DEST_REFERENCES_PATH -> $SOURCE_REFERENCES_DIR"
fi

if [[ "$VERIFY_LINKS" == "true" ]]; then
  verify_script="$SCRIPT_ROOT/codex/verify-skill-links.sh"
  if [[ ! -x "$verify_script" ]]; then
    echo "Verification script missing or not executable: $verify_script" >&2
    exit 1
  fi

  verify_cmd=(bash "$verify_script" --skills-dir "$DEST_SKILLS_DIR")
  if [[ "$DRY_RUN" == "true" ]]; then
    verify_cmd+=(--no-strict)
  fi
  run_cmd "${verify_cmd[@]}"
fi

echo "Scope: $SCOPE"
if [[ "$SCOPE" == "project" || "$SCOPE" == "local" ]]; then
  echo "Project root: $PROJECT_ROOT"
fi
echo "Done. Linked $linked_count skill(s) into $DEST_SKILLS_DIR."
