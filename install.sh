#!/bin/bash
# Dify Plugin Skill Installer
# Installs the skill globally or locally

set -e

SKILL_NAME="dify-plugin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SOURCE="$SCRIPT_DIR/skills/$SKILL_NAME"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --global, -g    Install to ~/.claude/skills/ (default)"
    echo "  --local, -l     Install to current project's .claude/skills/"
    echo "  --uninstall     Remove the skill"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Marketplace Installation (recommended):"
    echo "  In Claude Code, run:"
    echo "    /plugin marketplace add <your-github-username>/dify-plugin-skill"
    echo "    /plugin install dify-plugin@dify-plugin-skills"
    echo ""
    echo "Examples:"
    echo "  $0              # Global install"
    echo "  $0 --local      # Install to current project"
    echo "  $0 --uninstall  # Remove global installation"
}

install_skill() {
    local target_dir="$1"
    local install_type="$2"

    echo -e "${YELLOW}Installing $SKILL_NAME skill ($install_type)...${NC}"

    # Check if SKILL.md exists
    if [ ! -f "$SKILL_SOURCE/SKILL.md" ]; then
        echo -e "${RED}Error: SKILL.md not found in $SKILL_SOURCE${NC}"
        exit 1
    fi

    # Create target directory
    mkdir -p "$target_dir"

    # Remove existing installation if present
    if [ -d "$target_dir" ] && [ "$(ls -A "$target_dir" 2>/dev/null)" ]; then
        echo "Removing existing installation..."
        rm -rf "$target_dir"
        mkdir -p "$target_dir"
    fi

    # Copy skill files
    cp "$SKILL_SOURCE/SKILL.md" "$target_dir/"

    # Copy references if they exist
    if [ -d "$SKILL_SOURCE/references" ]; then
        cp -r "$SKILL_SOURCE/references" "$target_dir/"
    fi

    echo -e "${GREEN}Done!${NC} Skill installed to: $target_dir"
    echo ""
    echo "The skill is now available in Claude Code."
    echo "Start a new conversation and ask Claude to help you build a Dify plugin."
}

uninstall_skill() {
    local global_dir="$HOME/.claude/skills/$SKILL_NAME"
    local local_dir="$(pwd)/.claude/skills/$SKILL_NAME"
    local removed=0

    echo -e "${YELLOW}Uninstalling $SKILL_NAME skill...${NC}"

    if [ -d "$global_dir" ]; then
        rm -rf "$global_dir"
        echo "Removed global installation: $global_dir"
        removed=1
    fi

    if [ -d "$local_dir" ]; then
        rm -rf "$local_dir"
        echo "Removed local installation: $local_dir"
        removed=1
    fi

    if [ $removed -eq 0 ]; then
        echo "No installation found."
    else
        echo -e "${GREEN}Done!${NC}"
    fi
}

# Parse arguments
INSTALL_MODE="global"

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            INSTALL_MODE="global"
            shift
            ;;
        --local|-l)
            INSTALL_MODE="local"
            shift
            ;;
        --uninstall)
            uninstall_skill
            exit 0
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Determine target directory
if [ "$INSTALL_MODE" = "global" ]; then
    TARGET_DIR="$HOME/.claude/skills/$SKILL_NAME"
    install_skill "$TARGET_DIR" "global"
else
    TARGET_DIR="$(pwd)/.claude/skills/$SKILL_NAME"
    install_skill "$TARGET_DIR" "local"
fi
