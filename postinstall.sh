#!/bin/bash
# postinstall.sh — Creates .claude/commands/ symlinks so /ios-test and
# /add-accessibility work directly (without the plugin namespace prefix).
#
# Run automatically after `npx skills add`, or manually:
#   bash .agents/skills/swiftui-autotest-skill/postinstall.sh

set -e

# Determine skill root (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Determine project root (two levels up from .agents/skills/<name>/)
# If run from the cloned repo directly, use current directory
if [[ "$SCRIPT_DIR" == *".agents/skills/"* ]]; then
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
elif [[ "$SCRIPT_DIR" == *".claude/skills/"* ]]; then
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
else
  PROJECT_ROOT="$SCRIPT_DIR"
fi

COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"

# Find the commands source (prefer relative path through .claude/skills symlink)
if [ -d "$PROJECT_ROOT/.claude/skills/swiftui-autotest-skill/commands" ]; then
  SKILL_COMMANDS="../skills/swiftui-autotest-skill/commands"
elif [ -d "$PROJECT_ROOT/.agents/skills/swiftui-autotest-skill/commands" ]; then
  SKILL_COMMANDS="../../.agents/skills/swiftui-autotest-skill/commands"
else
  echo "Error: Could not find swiftui-autotest-skill commands directory."
  exit 1
fi

mkdir -p "$COMMANDS_DIR"

for cmd in ios-test add-accessibility; do
  TARGET="$SKILL_COMMANDS/$cmd.md"
  LINK="$COMMANDS_DIR/$cmd.md"

  if [ -e "$LINK" ]; then
    echo "  Skipped $cmd (already exists)"
  else
    ln -s "$TARGET" "$LINK"
    echo "  Linked /.$cmd -> $TARGET"
  fi
done

echo ""
echo "Done! You can now use /ios-test and /add-accessibility directly."
