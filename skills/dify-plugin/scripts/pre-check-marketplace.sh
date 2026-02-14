#!/usr/bin/env bash
#
# pre-check-marketplace.sh
#
# Local pre-flight check that mimics the Dify Marketplace CI pipeline
# (langgenius/dify-plugins) before you submit a PR.
#
# Usage:
#   ./pre-check-marketplace.sh <plugin-directory>
#
# Exit codes:
#   0 - all checks passed
#   1 - one or more checks failed
#
# Prerequisites:
#   - yq        (https://github.com/mikefarah/yq)
#   - curl
#   - dify CLI  (pip install dify-plugin-daemon, or the standalone binary)
#
set -euo pipefail

# ────────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

PASS="${GREEN}Pass${RESET}"
FAIL="${RED}FAIL${RESET}"
WARN="${YELLOW}Warn${RESET}"

FAILURES=0
WARNINGS=0

# Columns: Check (28), Status (10), Details (rest)
COL_CHECK=28
COL_STATUS=10

declare -a ROWS=()

add_row() {
    local check="$1" status="$2" details="${3:-}"
    ROWS+=("${check}|${status}|${details}")
}

fail() {
    add_row "$1" "FAIL" "$2"
    ((FAILURES++)) || true
}

pass() {
    add_row "$1" "Pass" "$2"
}

warn() {
    add_row "$1" "Warn" "$2"
    ((WARNINGS++)) || true
}

print_table() {
    local header
    printf "\n${BOLD}%-${COL_CHECK}s %-${COL_STATUS}s %s${RESET}\n" \
        "Check" "Status" "Details"
    # Unicode box-drawing line
    printf '%0.s─' $(seq 1 70)
    printf '\n'

    for row in "${ROWS[@]}"; do
        IFS='|' read -r check status details <<< "$row"
        local color=""
        local icon=""
        case "$status" in
            Pass) color="$GREEN"; icon="+" ;;
            FAIL) color="$RED";   icon="x" ;;
            Warn) color="$YELLOW"; icon="!" ;;
        esac
        printf "%-${COL_CHECK}s ${color}%-${COL_STATUS}s${RESET} %s\n" \
            "$check" "[$icon] $status" "$details"
    done

    printf '%0.s─' $(seq 1 70)
    printf '\n'
}

# ────────────────────────────────────────────────────────────────────
# Argument handling
# ────────────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <plugin-directory>"
    exit 2
fi

PLUGIN_DIR="$(cd "$1" && pwd)"

if [[ ! -d "$PLUGIN_DIR" ]]; then
    echo "Error: '$1' is not a directory."
    exit 2
fi

MANIFEST="$PLUGIN_DIR/manifest.yaml"

if [[ ! -f "$MANIFEST" ]]; then
    echo "Error: No manifest.yaml found in '$PLUGIN_DIR'."
    echo "       Are you sure this is a Dify plugin directory?"
    exit 2
fi

echo ""
echo "${BOLD}Dify Marketplace Pre-Check${RESET}"
echo "Plugin directory: $PLUGIN_DIR"
echo ""

# ────────────────────────────────────────────────────────────────────
# 1. Project structure: README.md
# ────────────────────────────────────────────────────────────────────
if [[ -f "$PLUGIN_DIR/README.md" ]]; then
    pass "README.md exists" ""
else
    fail "README.md exists" "Missing README.md in plugin root"
fi

# ────────────────────────────────────────────────────────────────────
# 2. Project structure: PRIVACY.md (existence + non-empty)
# ────────────────────────────────────────────────────────────────────
if [[ -f "$PLUGIN_DIR/PRIVACY.md" ]]; then
    if [[ -s "$PLUGIN_DIR/PRIVACY.md" ]]; then
        pass "PRIVACY.md exists" ""
    else
        fail "PRIVACY.md exists" "PRIVACY.md is empty"
    fi
else
    fail "PRIVACY.md exists" "Missing PRIVACY.md in plugin root"
fi

# ────────────────────────────────────────────────────────────────────
# 3. Manifest: author must not be langgenius or dify
# ────────────────────────────────────────────────────────────────────
AUTHOR="$(yq -r '.author // ""' "$MANIFEST")"
PLUGIN_NAME="$(yq -r '.name // ""' "$MANIFEST")"
PLUGIN_VERSION="$(yq -r '.version // ""' "$MANIFEST")"

if [[ -z "$AUTHOR" ]]; then
    fail "Manifest author" "author field is missing or empty"
elif [[ "$AUTHOR" == "langgenius" || "$AUTHOR" == "dify" ]]; then
    fail "Manifest author" "author='$AUTHOR' is reserved"
else
    pass "Manifest author" "author=$AUTHOR"
fi

# ────────────────────────────────────────────────────────────────────
# 4. Icon validation
# ────────────────────────────────────────────────────────────────────
ICON="$(yq -r '.icon // ""' "$MANIFEST")"
ICON_PATH="$PLUGIN_DIR/_assets/$ICON"

if [[ -z "$ICON" ]]; then
    fail "Icon valid" "icon field missing in manifest.yaml"
elif [[ ! -f "$ICON_PATH" ]]; then
    fail "Icon valid" "_assets/$ICON not found"
else
    # Check for the template placeholder marker
    if grep -q 'DIFY_MARKETPLACE_TEMPLATE_ICON_DO_NOT_USE' "$ICON_PATH" 2>/dev/null; then
        fail "Icon valid" "Icon contains DIFY_MARKETPLACE_TEMPLATE_ICON_DO_NOT_USE marker"
    else
        # Check if it is the known default template SVG (the cookiecutter default).
        # The default template icon starts with a specific SVG comment.
        # We use a lightweight heuristic: file size < 100 bytes is suspicious.
        ICON_SIZE=$(stat -c%s "$ICON_PATH" 2>/dev/null || stat -f%z "$ICON_PATH" 2>/dev/null || echo 0)
        if [[ "$ICON_SIZE" -eq 0 ]]; then
            fail "Icon valid" "Icon file is empty (0 bytes)"
        else
            pass "Icon valid" "$ICON (${ICON_SIZE}B)"
        fi
    fi
fi

# ────────────────────────────────────────────────────────────────────
# 5. README language: no CJK characters
#    Ranges: U+4E00-U+9FFF  (CJK Unified Ideographs)
#            U+3000-U+303F  (CJK Symbols and Punctuation)
#            U+FF00-U+FFEF  (Halfwidth and Fullwidth Forms)
#            U+3400-U+4DBF  (CJK Unified Ideographs Extension A)
# ────────────────────────────────────────────────────────────────────
if [[ -f "$PLUGIN_DIR/README.md" ]]; then
    # Use perl for reliable Unicode range matching
    CJK_MATCHES=$(perl -CSD -ne '
        while (/[\x{4E00}-\x{9FFF}\x{3000}-\x{303F}\x{FF00}-\x{FFEF}\x{3400}-\x{4DBF}]/g) {
            $count++;
        }
        END { print $count // 0 }
    ' "$PLUGIN_DIR/README.md" 2>/dev/null || echo "0")

    if [[ "$CJK_MATCHES" -gt 0 ]]; then
        fail "README language" "Found $CJK_MATCHES CJK character(s) - English only"
    else
        pass "README language" "No CJK characters found"
    fi
else
    # Already reported above; skip duplicate
    :
fi

# ────────────────────────────────────────────────────────────────────
# 6. requirements.txt exists
# ────────────────────────────────────────────────────────────────────
if [[ -f "$PLUGIN_DIR/requirements.txt" ]]; then
    pass "requirements.txt" ""
else
    fail "requirements.txt" "Missing requirements.txt (needed for CI install test)"
fi

# ────────────────────────────────────────────────────────────────────
# 7. dify-plugin version >= 0.5.0
# ────────────────────────────────────────────────────────────────────
check_dify_plugin_version() {
    local version_str=""

    # Try requirements.txt first
    if [[ -f "$PLUGIN_DIR/requirements.txt" ]]; then
        # Match lines like: dify-plugin>=0.5.0  or  dify_plugin==0.6.1
        version_str=$(grep -iE '^dify[-_]plugin' "$PLUGIN_DIR/requirements.txt" 2>/dev/null | head -1 || true)
    fi

    # Fallback to pyproject.toml
    if [[ -z "$version_str" && -f "$PLUGIN_DIR/pyproject.toml" ]]; then
        version_str=$(grep -iE 'dify[-_]plugin' "$PLUGIN_DIR/pyproject.toml" 2>/dev/null | head -1 || true)
    fi

    if [[ -z "$version_str" ]]; then
        fail "dify-plugin version" "dify-plugin not found in requirements.txt or pyproject.toml"
        return
    fi

    # Extract the version number (first occurrence of X.Y.Z pattern)
    local ver
    ver=$(echo "$version_str" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)

    if [[ -z "$ver" ]]; then
        warn "dify-plugin version" "Could not parse version from: $version_str"
        return
    fi

    # Compare: need >= 0.5.0
    local major minor patch
    IFS='.' read -r major minor patch <<< "$ver"

    if [[ "$major" -gt 0 ]] ||
       [[ "$major" -eq 0 && "$minor" -gt 5 ]] ||
       [[ "$major" -eq 0 && "$minor" -eq 5 && "$patch" -ge 0 ]]; then
        pass "dify-plugin version" ">= 0.5.0 ($ver)"
    else
        fail "dify-plugin version" "$ver < 0.5.0 required"
    fi
}
check_dify_plugin_version

# ────────────────────────────────────────────────────────────────────
# 8. No junk / dev-only files that would get packaged
# ────────────────────────────────────────────────────────────────────
JUNK_ITEMS=(
    ".pytest_cache"
    ".ruff_cache"
    ".credentials"
    "debug.log"
    "uv.lock"
    "tests"
    ".venv"
)

JUNK_FOUND=()
for item in "${JUNK_ITEMS[@]}"; do
    if [[ -e "$PLUGIN_DIR/$item" ]]; then
        JUNK_FOUND+=("$item")
    fi
done

if [[ ${#JUNK_FOUND[@]} -eq 0 ]]; then
    pass "No junk files" "Clean"
else
    warn "No junk files" "Found: ${JUNK_FOUND[*]}"
fi

# ────────────────────────────────────────────────────────────────────
# 9. Package test: dify plugin package <dir>
# ────────────────────────────────────────────────────────────────────
if command -v dify &>/dev/null; then
    PACKAGE_OUTPUT=$(dify plugin package "$PLUGIN_DIR" 2>&1) && PACKAGE_RC=$? || PACKAGE_RC=$?
    if [[ $PACKAGE_RC -eq 0 ]]; then
        # Extract .difypkg filename if present
        PKG_FILE=$(echo "$PACKAGE_OUTPUT" | grep -oE '[^ ]+\.difypkg' | tail -1 || true)
        pass "Package test" "${PKG_FILE:-succeeded}"
    else
        # Grab the last meaningful line of output for context
        LAST_LINE=$(echo "$PACKAGE_OUTPUT" | tail -3 | head -1)
        fail "Package test" "Exit $PACKAGE_RC: $LAST_LINE"
    fi
else
    warn "Package test" "dify CLI not found - skipping"
fi

# ────────────────────────────────────────────────────────────────────
# 10. Version check against marketplace API
# ────────────────────────────────────────────────────────────────────
if [[ -n "$AUTHOR" && -n "$PLUGIN_NAME" && -n "$PLUGIN_VERSION" ]]; then
    API_URL="https://marketplace.dify.ai/api/v1/plugins/${AUTHOR}/${PLUGIN_NAME}/${PLUGIN_VERSION}"
    HTTP_CODE=$(curl -s -o /tmp/marketplace_response.json -w '%{http_code}' "$API_URL" 2>/dev/null || echo "000")

    if [[ "$HTTP_CODE" == "200" ]]; then
        API_CODE=$(yq -r '.code // ""' /tmp/marketplace_response.json 2>/dev/null || echo "")
        if [[ "$API_CODE" == "0" ]]; then
            fail "Version check" "v$PLUGIN_VERSION already exists on marketplace"
        else
            pass "Version check" "v$PLUGIN_VERSION available (API code=$API_CODE)"
        fi
    elif [[ "$HTTP_CODE" == "000" ]]; then
        warn "Version check" "Could not reach marketplace API"
    else
        pass "Version check" "v$PLUGIN_VERSION not on marketplace (HTTP $HTTP_CODE)"
    fi
    rm -f /tmp/marketplace_response.json
else
    warn "Version check" "Missing author/name/version in manifest"
fi

# ────────────────────────────────────────────────────────────────────
# Summary
# ────────────────────────────────────────────────────────────────────
print_table

echo ""
if [[ $FAILURES -gt 0 ]]; then
    printf "${RED}${BOLD}%d check(s) failed.${RESET}" "$FAILURES"
    if [[ $WARNINGS -gt 0 ]]; then
        printf "  ${YELLOW}%d warning(s).${RESET}" "$WARNINGS"
    fi
    echo ""
    echo ""
    echo "Fix the failures above before submitting to the Dify Marketplace."
    echo ""
    echo "PR template checklist reminder:"
    echo "  - README with setup + usage instructions (English only)"
    echo "  - PRIVACY.md with data collection & privacy policy info"
    echo "  - Plugin tested on Community Edition and Cloud Version"
    echo "  - Repository URL included in PR body"
    echo "  - Plugin Developer Agreement acknowledged"
    exit 1
else
    printf "${GREEN}${BOLD}All checks passed!${RESET}"
    if [[ $WARNINGS -gt 0 ]]; then
        printf "  ${YELLOW}%d warning(s) - review recommended.${RESET}" "$WARNINGS"
    fi
    echo ""
    echo ""
    echo "Your plugin looks ready for marketplace submission."
    echo ""
    echo "PR body template fields to fill:"
    echo "  1. Plugin Author:    $AUTHOR"
    echo "  2. Plugin Name:      $PLUGIN_NAME"
    echo "  3. Repository URL:   <your-repo-url>"
    echo "  4. Submission Type:  New plugin / Version update"
    echo "  5. Description:      <what your plugin does>"
    echo "  6. Checklists:       Review all boxes in the PR template"
    exit 0
fi
