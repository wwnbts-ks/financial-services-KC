#!/usr/bin/env bash
# Pull Anthropic's upstream updates into your fork's customization branch.
#
# This repo is installed as a local "directory" marketplace, so Claude Code's
# notion of "upstream" is THIS directory — official upgrades from
# anthropics/financial-services do NOT arrive automatically. This script does
# the manual git side for you:
#
#   1. fetch upstream (anthropics/financial-services)
#   2. fast-forward your local `main` to upstream/main
#   3. merge `main` into your customization branch
#
# It is conservative: it refuses to run with uncommitted changes, stops on the
# first merge conflict so you can resolve it by hand, and never pushes. After it
# succeeds you still need to refresh the plugin in Claude Code (bump already
# comes from upstream) and restart your session for skills to reload.
#
# Usage:
#   scripts/pull-upstream.sh                 # merge into the current branch
#   scripts/pull-upstream.sh <branch>        # merge into a specific branch
#   UPSTREAM=anthropic scripts/pull-upstream.sh   # override remote name
set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

UPSTREAM="${UPSTREAM:-upstream}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"
TARGET_BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"

say()  { printf '\033[1;34m[pull-upstream]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[pull-upstream]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[pull-upstream]\033[0m %s\n' "$*" >&2; exit 1; }

# --- preflight ---------------------------------------------------------------
git remote get-url "$UPSTREAM" >/dev/null 2>&1 \
  || die "no '$UPSTREAM' remote. Add it: git remote add $UPSTREAM https://github.com/anthropics/financial-services.git"

if ! git diff --quiet || ! git diff --cached --quiet; then
  die "you have uncommitted changes. Commit or stash them first, then re-run."
fi

START_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
restore() { git checkout --quiet "$START_BRANCH" 2>/dev/null || true; }

# --- 1. fetch upstream -------------------------------------------------------
say "fetching $UPSTREAM ..."
git fetch "$UPSTREAM" --prune

# Nothing new? Bail early.
BEHIND="$(git rev-list --count "$MAIN_BRANCH..$UPSTREAM/$MAIN_BRANCH" 2>/dev/null || echo 0)"
if [ "$BEHIND" = "0" ]; then
  say "already up to date with $UPSTREAM/$MAIN_BRANCH — nothing to pull."
  exit 0
fi
say "$UPSTREAM/$MAIN_BRANCH is $BEHIND commit(s) ahead of your $MAIN_BRANCH."

# --- 2. fast-forward local main to upstream/main -----------------------------
say "updating local '$MAIN_BRANCH' ..."
git checkout --quiet "$MAIN_BRANCH"
if ! git merge --ff-only "$UPSTREAM/$MAIN_BRANCH"; then
  warn "local '$MAIN_BRANCH' has diverged from $UPSTREAM/$MAIN_BRANCH (not a clean fast-forward)."
  warn "Your '$MAIN_BRANCH' should track upstream untouched — make customizations on a branch."
  restore
  die "resolve '$MAIN_BRANCH' manually, then re-run."
fi

# --- 3. merge main into the customization branch -----------------------------
say "merging '$MAIN_BRANCH' into '$TARGET_BRANCH' ..."
git checkout --quiet "$TARGET_BRANCH"
if ! git merge --no-edit "$MAIN_BRANCH"; then
  warn "merge stopped on conflicts. Resolve them, then:"
  warn "    git add <files> && git commit"
  warn "Conflicted files:"
  git diff --name-only --diff-filter=U | sed 's/^/      /' >&2
  exit 1   # leave the working tree mid-merge for the user
fi

say "done — '$TARGET_BRANCH' now includes upstream updates."
echo
say "NEXT (so Claude Code actually serves the new skills):"
echo "    1. Update the 'equity-research'/'financial-analysis' plugin in Claude Code"
echo "       (the directory marketplace re-caches when plugin.json version changed)."
echo "    2. Restart your Claude Code session — skills load fresh on startup."
