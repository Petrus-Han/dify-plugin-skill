#!/bin/bash
# Dify Plugin Skill Installer
# Installs the skill to ~/.claude/skills/ for global availability

set -e

SKILL_NAME="dify-plugin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.claude/skills/$SKILL_NAME"

echo "Installing $SKILL_NAME skill..."

# Check if SKILL.md exists in repo root
if [ ! -f "$SCRIPT_DIR/SKILL.md" ]; then
    echo "Error: SKILL.md not found in $SCRIPT_DIR"
    exit 1
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Remove existing installation if present
if [ -d "$TARGET_DIR" ]; then
    echo "Removing existing installation..."
    rm -rf "$TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

# Copy skill files from repo root
cp "$SCRIPT_DIR/SKILL.md" "$TARGET_DIR/"
cp -r "$SCRIPT_DIR/references" "$TARGET_DIR/"

echo "Done! Skill installed to: $TARGET_DIR"
echo ""
echo "The skill is now globally available in Claude Code."
echo "Start a new conversation and ask Claude to help you build a Dify plugin."
