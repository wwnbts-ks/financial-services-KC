#!/usr/bin/env bash
# Live-load a plugin skill for local development.
#
# Plugin skills are served from a version-gated cache: until a plugin's
# .claude-plugin/plugin.json `version` changes, Claude Code will NOT re-deliver
# your in-progress edits to you (you are an already-installed user of your own
# plugin). Project skills under .claude/skills/ have no such gate — they are
# read fresh on every session start. This symlinks a plugin skill in there so
# you can iterate with just a session restart: no version bump, no reinstall.
#
# Usage:
#   scripts/dev-link-skill.sh <vertical> <skill>     # link for live dev
#   scripts/dev-link-skill.sh --unlink <skill>       # remove when done
#   scripts/dev-link-skill.sh --list                 # show active dev links
#
# Examples:
#   scripts/dev-link-skill.sh equity-research executive-incentive-analysis
#   scripts/dev-link-skill.sh --unlink executive-incentive-analysis
#
# .claude/skills/ is gitignored, so dev links never leak into other clones
# (which would otherwise see a duplicate of the skill that already ships in the
# plugin). When the skill is stable, --unlink it; it ships normally via the
# plugin's version bump on merge to main.
set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
SKILLS_DIR="$REPO_ROOT/.claude/skills"
PLUGINS_GLOB_BASE="$REPO_ROOT/plugins/vertical-plugins"

die() { echo "error: $*" >&2; exit 1; }

cmd_list() {
  if [ ! -d "$SKILLS_DIR" ]; then
    echo "(no dev-linked skills)"
    return 0
  fi
  local found=0
  for entry in "$SKILLS_DIR"/*; do
    [ -L "$entry" ] || continue
    found=1
    printf "%-40s -> %s\n" "$(basename "$entry")" "$(readlink "$entry")"
  done
  [ "$found" = 1 ] || echo "(no dev-linked skills)"
}

cmd_unlink() {
  local skill="$1"
  local link="$SKILLS_DIR/$skill"
  [ -L "$link" ] || die "no dev link found at $link"
  rm "$link"
  echo "[dev-link] unlinked $skill — restart your Claude Code session to drop it"
  # Clean up an empty .claude/skills/ so the tree stays tidy.
  rmdir "$SKILLS_DIR" 2>/dev/null || true
}

cmd_link() {
  local vertical="$1" skill="$2"
  local src="$PLUGINS_GLOB_BASE/$vertical/skills/$skill"
  [ -d "$src" ] || die "skill source not found: $src"
  [ -f "$src/SKILL.md" ] || die "no SKILL.md in $src — not a skill directory"

  mkdir -p "$SKILLS_DIR"
  local link="$SKILLS_DIR/$skill"
  if [ -e "$link" ] || [ -L "$link" ]; then
    rm "$link"
  fi
  # Relative symlink so the repo stays portable across machines.
  ln -s "../../plugins/vertical-plugins/$vertical/skills/$skill" "$link"
  echo "[dev-link] linked $vertical/$skill -> .claude/skills/$skill"
  echo "[dev-link] restart your Claude Code session to load it (live, no version bump needed)"
}

main() {
  case "${1:-}" in
    --list)   cmd_list ;;
    --unlink) [ $# -eq 2 ] || die "usage: $0 --unlink <skill>"; cmd_unlink "$2" ;;
    "" | -h | --help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      ;;
    *)
      [ $# -eq 2 ] || die "usage: $0 <vertical> <skill>   (see --help)"
      cmd_link "$1" "$2"
      ;;
  esac
}

main "$@"
