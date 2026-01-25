#!/bin/bash
# Dify Plugin Development - Repository Setup Script
# Downloads all essential repositories for plugin development
#
# Usage:
#   ./setup-repositories.sh [target_directory]
#
# If no target directory specified, will prompt for input

set -e

# Repository list (compatible with bash 3.x)
REPO_NAMES="dify dify-plugin-daemon dify-official-plugins dify-plugin-sdks dify-docs"

get_repo_url() {
    echo "https://github.com/langgenius/$1.git"
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

RECOMMENDED_DIR="$HOME/Source/dify-dev-reference-repo"

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed. Please install git to continue.${NC}"
    exit 1
fi

echo "=================================================="
echo "Dify Plugin Development - Repository Setup"
echo "=================================================="
echo ""

# Determine target directory
if [ -n "$1" ]; then
    TARGET_DIR="$1"
else
    echo "These repositories are essential for Dify plugin development:"
    echo ""
    echo "  - dify                  : Core platform (manifest schemas, daemon client)"
    echo "  - dify-plugin-daemon    : Plugin runtime (CLI, protocol specs)"
    echo "  - dify-official-plugins : Official examples (reference implementations)"
    echo "  - dify-plugin-sdks      : Python/Go SDKs (dify_plugin package)"
    echo "  - dify-docs             : Documentation (guides, API references)"
    echo ""
    echo -e "${BLUE}Recommended directory: ${RECOMMENDED_DIR}${NC}"
    echo ""
    read -p "Where would you like to clone these repositories? [${RECOMMENDED_DIR}]: " USER_INPUT

    # Use recommended directory if user just presses Enter
    TARGET_DIR="${USER_INPUT:-$RECOMMENDED_DIR}"
fi

# Expand ~ if present
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

echo ""
echo -e "Target directory: ${GREEN}$TARGET_DIR${NC}"
echo ""

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Creating directory: $TARGET_DIR${NC}"
    mkdir -p "$TARGET_DIR"
fi

cd "$TARGET_DIR"

# Clone or update each repository
for repo_name in $REPO_NAMES; do
    repo_url=$(get_repo_url "$repo_name")
    repo_path="$TARGET_DIR/$repo_name"

    echo "-------------------------------------------"
    echo "Repository: $repo_name"

    if [ -d "$repo_path" ]; then
        echo -e "${YELLOW}Already exists. Pulling latest...${NC}"
        cd "$repo_path"
        git pull --ff-only 2>/dev/null || echo -e "${YELLOW}Pull skipped (uncommitted changes or diverged)${NC}"
        cd "$TARGET_DIR"
    else
        echo -e "${GREEN}Cloning...${NC}"
        git clone "$repo_url" "$repo_path"
    fi

    echo -e "${GREEN}Done: $repo_name${NC}"
done

echo ""
echo "=================================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=================================================="
echo ""
echo "Repositories are located at: $TARGET_DIR"
echo ""
echo "Next step: Add these paths to your Claude Code working directories:"
echo ""
echo "  /settings add workingDirectories $TARGET_DIR/dify"
echo "  /settings add workingDirectories $TARGET_DIR/dify-plugin-daemon"
echo "  /settings add workingDirectories $TARGET_DIR/dify-official-plugins"
echo "  /settings add workingDirectories $TARGET_DIR/dify-plugin-sdks"
echo "  /settings add workingDirectories $TARGET_DIR/dify-docs"
echo ""
