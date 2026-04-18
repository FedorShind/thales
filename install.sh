#!/usr/bin/env bash
# Thales installer — copies skills and agents into a target project's .claude/
# and scaffolds _scratch/thales/ from the ledger template.
#
# Usage:  ./install.sh /path/to/target-project
#
# Idempotent: re-running updates skill/agent files in place. Does not overwrite
# an existing _scratch/thales/ ledger — prompts instead.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/target-project" >&2
    exit 1
fi

TARGET="$1"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$TARGET" ]]; then
    echo "Target directory does not exist: $TARGET" >&2
    exit 1
fi

SKILLS_DST="$TARGET/.claude/skills"
AGENTS_DST="$TARGET/.claude/agents"
SCRATCH_DST="$TARGET/_scratch/thales"

mkdir -p "$SKILLS_DST"
mkdir -p "$AGENTS_DST"

# Copy skills (overwrites are intentional — skill updates should land)
echo "Installing skills to $SKILLS_DST"
cp -R "$SOURCE_DIR/skills/thales" "$SKILLS_DST/"
cp -R "$SOURCE_DIR/skills/thales-start" "$SKILLS_DST/"
cp -R "$SOURCE_DIR/skills/thales-status" "$SKILLS_DST/"
cp -R "$SOURCE_DIR/skills/thales-checkpoint" "$SKILLS_DST/"
cp -R "$SOURCE_DIR/skills/thales-resume" "$SKILLS_DST/"
cp -R "$SOURCE_DIR/skills/thales-prune" "$SKILLS_DST/"

# Copy agents (overwrites intentional)
echo "Installing agents to $AGENTS_DST"
cp "$SOURCE_DIR"/agents/*.md "$AGENTS_DST/"

# Scaffold _scratch/thales/ from the ledger template — but only if it does not exist
if [[ -d "$SCRATCH_DST" ]]; then
    echo "Existing $SCRATCH_DST found. Not overwriting."
    echo "If you want a fresh scaffold, remove or rename the existing directory and re-run."
else
    echo "Scaffolding $SCRATCH_DST from ledger template"
    mkdir -p "$SCRATCH_DST/branches"
    mkdir -p "$SCRATCH_DST/verdicts"
    cp "$SOURCE_DIR/skills/thales/assets/ledger_template/task.md" "$SCRATCH_DST/"
    cp "$SOURCE_DIR/skills/thales/assets/ledger_template/ledger.md" "$SCRATCH_DST/"
    cp "$SOURCE_DIR/skills/thales/assets/ledger_template/ruled_out.md" "$SCRATCH_DST/"
    cp "$SOURCE_DIR/skills/thales/assets/ledger_template/dead_ends.md" "$SCRATCH_DST/"
    cp "$SOURCE_DIR/skills/thales/assets/ledger_template/open_questions.md" "$SCRATCH_DST/"
fi

# Ensure _scratch/ is in .gitignore of the target project
GITIGNORE="$TARGET/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
    if ! grep -Fxq "_scratch/" "$GITIGNORE"; then
        echo "_scratch/" >> "$GITIGNORE"
        echo "Added _scratch/ to $GITIGNORE"
    fi
else
    echo "_scratch/" > "$GITIGNORE"
    echo "Created $GITIGNORE with _scratch/ entry"
fi

echo ""
echo "Thales installed."
echo "  Skills:  $SKILLS_DST"
echo "  Agents:  $AGENTS_DST"
echo "  Scratch: $SCRATCH_DST"
echo ""
echo "In a Claude Code session in $TARGET, invoke with: 'Use Thales: <your task>'"
