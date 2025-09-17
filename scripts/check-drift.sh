#!/bin/bash
# living-docs drift detection and auto-fix tool
# Finds and fixes orphaned files and missing links in documentation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
DRY_RUN=false
VERBOSE=false
AUTO_FIX=true

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            AUTO_FIX=false
            shift
            ;;
        --no-fix)
            AUTO_FIX=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be fixed without making changes"
            echo "  --no-fix     Only detect drift, don't fix it"
            echo "  -v, --verbose Show detailed output"
            echo "  -h, --help   Show this help message"
            exit 0
            ;;
    esac
done

echo "🔍 Checking for documentation drift..."
[ "$DRY_RUN" = true ] && echo -e "${YELLOW}(DRY RUN - no changes will be made)${NC}"

# Find all markdown files
ALL_MD_FILES=$(find . -name "*.md" -type f | grep -v node_modules | grep -v .git | grep -v "/test-" | sort)

# Track changes for summary
FIXED_ORPHANS=0
FIXED_BROKEN=0
FIXED_COUNTS=0

# Check for orphaned files (not linked in current.md)
echo ""
echo "Checking for orphaned documentation..."
ORPHANED_FILES=()

for file in $ALL_MD_FILES; do
    # Skip current.md itself, README, and root AI files
    if [[ "$file" == "./docs/current.md" ]] || [[ "$file" == "./README.md" ]] || [[ "$file" == "./CLAUDE.md" ]] || [[ "$file" == "./AI.md" ]]; then
        continue
    fi

    # Convert file path to link format
    REL_PATH=$(echo "$file" | sed 's/^\.\///')

    # Get just the filename without date prefix for searching
    BASE_NAME=$(basename "$file" .md | sed 's/^[0-9]*-[0-9]*-[0-9]*-//' | sed 's/^[0-9]*-//')

    # Check if linked in current.md (search for both full path and base name)
    if ! grep -q "$REL_PATH" docs/current.md 2>/dev/null && \
       ! grep -q "$BASE_NAME" docs/current.md 2>/dev/null; then
        echo -e "${YELLOW}⚠ Orphaned:${NC} $file"
        ORPHANED_FILES+=("$file")
    fi
done

# Auto-fix orphaned files
if [ ${#ORPHANED_FILES[@]} -gt 0 ] && [ "$AUTO_FIX" = true ]; then
    echo -e "${BLUE}→ Auto-fixing orphaned files...${NC}"

    for file in "${ORPHANED_FILES[@]}"; do
        # Determine section based on path
        SECTION=""
        LINK_TEXT=""

        if [[ "$file" == *"/active/"* ]]; then
            SECTION="## 🔥 Active Development"
            LINK_TEXT=$(basename "$file" .md | sed 's/^[0-9]*-//')
        elif [[ "$file" == *"/completed/"* ]]; then
            SECTION="## ✅ Recently Completed"
            LINK_TEXT=$(basename "$file" .md | sed 's/^[0-9]*-[0-9]*-[0-9]*-//')
        elif [[ "$file" == *"/archived/"* ]]; then
            # Skip archived files - they should NOT be in current.md
            continue
        elif [[ "$file" == *"/procedures/"* ]]; then
            SECTION="### Development History"
            LINK_TEXT=$(basename "$file" .md)
        elif [[ "$file" == "./docs/specs/"* ]]; then
            SECTION="### Specifications"
            LINK_TEXT=$(basename "$file" .md)
        elif [[ "$file" == "./specs/"*.md ]]; then
            # Old location - should be moved
            SECTION="### Spec Adapters"
            LINK_TEXT=$(basename "$file" .md)
        elif [[ "$file" == "./templates/"* ]]; then
            SECTION="### Templates"
            LINK_TEXT=$(basename "$file")
        elif [[ "$file" == *"/.claude/"* ]] || [[ "$file" == *"/.specify/"* ]]; then
            # Skip spec-kit internal files
            continue
        elif [[ "$file" == "./adapters/"* ]]; then
            # Skip adapter internal templates
            continue
        elif [[ "$file" == "./scripts/"* ]]; then
            SECTION="### Scripts"
            LINK_TEXT=$(basename "$file")
        elif [[ "$file" == "./.githooks/"* ]]; then
            SECTION="### Git Integration"
            LINK_TEXT=$(basename "$file")
        else
            # Default to uncategorized - AI will want to fix this!
            SECTION="## ⚠️ UNCATEGORIZED - NEEDS ORGANIZATION"
            LINK_TEXT=$(basename "$file" .md)
        fi

        if [ -n "$SECTION" ]; then
            # Create the link line - fix path calculation
            if [[ "$file" == "./docs/"* ]]; then
                # File is in docs/, make relative path from docs/
                REL_FROM_DOCS=$(echo "$file" | sed 's|^\./docs/||')
            else
                # File is outside docs/, use ../ prefix
                REL_FROM_DOCS="../${REL_PATH}"
            fi

            # Add warning emoji for uncategorized items
            if [[ "$SECTION" == *"UNCATEGORIZED"* ]]; then
                LINK_LINE="- ⚠️ [$LINK_TEXT]($REL_FROM_DOCS) - **NEEDS CATEGORIZATION AND DESCRIPTION**"
            else
                LINK_LINE="- [$LINK_TEXT]($REL_FROM_DOCS) - [Description needed]"
            fi

            if [ "$DRY_RUN" = true ]; then
                echo "  Would add to $SECTION: $LINK_LINE"
            else
                # Double-check it's not already there (may have been added in a previous run)
                if grep -q "$LINK_TEXT" docs/current.md; then
                    echo "  ✓ Already listed: $LINK_TEXT"
                elif grep -q "^$SECTION" docs/current.md; then
                    # Add after section header
                    awk -v section="$SECTION" -v link="$LINK_LINE" '
                        $0 ~ section { print; getline; print; print link; next }
                        { print }
                    ' docs/current.md > docs/current.md.tmp && mv docs/current.md.tmp docs/current.md
                    echo "  ✓ Added $LINK_TEXT to $SECTION"
                    FIXED_ORPHANS=$((FIXED_ORPHANS + 1))
                fi
            fi
        fi
    done
fi

if [ ${#ORPHANED_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No orphaned files found${NC}"
fi

# Check for broken links in current.md
echo ""
echo "Checking for broken links in current.md..."
BROKEN_LINKS=()

# Extract all markdown links from current.md
LINKS=$(grep -o '\[.*\]([^)]*\.md[^)]*)' docs/current.md 2>/dev/null | sed 's/.*(\(.*\))/\1/' || true)

for link in $LINKS; do
    # Remove anchor if present
    FILE_PATH=$(echo "$link" | sed 's/#.*//')

    # Convert relative path
    if [[ "$FILE_PATH" == "../"* ]]; then
        CHECK_PATH=$(echo "$FILE_PATH" | sed 's/^\.\.\//\.\//')
    elif [[ "$FILE_PATH" == "./"* ]]; then
        CHECK_PATH="./docs/${FILE_PATH#./}"
    else
        CHECK_PATH="./docs/$FILE_PATH"
    fi

    # Check if file exists
    if [ ! -f "$CHECK_PATH" ]; then
        echo -e "${RED}✗ Broken link:${NC} $link"
        BROKEN_LINKS+=("$link")
    fi
done

# Auto-fix broken links
if [ ${#BROKEN_LINKS[@]} -gt 0 ] && [ "$AUTO_FIX" = true ]; then
    echo -e "${BLUE}→ Auto-fixing broken links...${NC}"

    for link in "${BROKEN_LINKS[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            echo "  Would remove broken link: $link"
        else
            # Comment out the line with the broken link
            sed -i '' "s|.*$link.*|<!-- BROKEN: & -->|g" docs/current.md
            echo "  ✓ Commented out broken link: $link"
            FIXED_BROKEN=$((FIXED_BROKEN + 1))
        fi
    done
fi

if [ ${#BROKEN_LINKS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No broken links found${NC}"
fi

# Fix bug/idea counts
echo ""
echo "Checking counts..."

if [ -f "docs/bugs.md" ]; then
    ACTUAL_BUGS=$(grep -c "^- \[ \]" docs/bugs.md || echo 0)
    CLAIMED_BUGS=$(grep "bugs.md.*Current count:" docs/current.md | grep -o "[0-9]* open" | grep -o "[0-9]*" || echo 0)

    if [ "$ACTUAL_BUGS" != "$CLAIMED_BUGS" ]; then
        echo -e "${YELLOW}⚠ Bug count mismatch:${NC} says $CLAIMED_BUGS but actually $ACTUAL_BUGS"

        if [ "$AUTO_FIX" = true ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  Would update bug count to $ACTUAL_BUGS"
            else
                sed -i '' "s/Current count: [0-9]* open/Current count: $ACTUAL_BUGS open/g" docs/current.md
                echo "  ✓ Updated bug count to $ACTUAL_BUGS"
                FIXED_COUNTS=$((FIXED_COUNTS + 1))
            fi
        fi
    fi
fi

if [ -f "docs/ideas.md" ]; then
    ACTUAL_IDEAS=$(grep -c "^- \[ \]" docs/ideas.md || echo 0)
    CLAIMED_IDEAS=$(grep "ideas.md.*Current count:" docs/current.md | grep -o "[0-9]* ideas" | grep -o "[0-9]*" || echo 0)

    if [ "$ACTUAL_IDEAS" != "$CLAIMED_IDEAS" ]; then
        echo -e "${YELLOW}⚠ Ideas count mismatch:${NC} says $CLAIMED_IDEAS but actually $ACTUAL_IDEAS"

        if [ "$AUTO_FIX" = true ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "  Would update ideas count to $ACTUAL_IDEAS"
            else
                sed -i '' "s/Current count: [0-9]* ideas/Current count: $ACTUAL_IDEAS ideas/g" docs/current.md
                echo "  ✓ Updated ideas count to $ACTUAL_IDEAS"
                FIXED_COUNTS=$((FIXED_COUNTS + 1))
            fi
        fi
    fi
fi

# Summary
echo ""
echo "═══════════════════════════════════"

TOTAL_ISSUES=$((${#ORPHANED_FILES[@]} + ${#BROKEN_LINKS[@]}))
TOTAL_FIXED=$((FIXED_ORPHANS + FIXED_BROKEN + FIXED_COUNTS))

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN SUMMARY:${NC}"
    echo "  Would fix $TOTAL_ISSUES issues"
    [ ${#ORPHANED_FILES[@]} -gt 0 ] && echo "  - ${#ORPHANED_FILES[@]} orphaned files"
    [ ${#BROKEN_LINKS[@]} -gt 0 ] && echo "  - ${#BROKEN_LINKS[@]} broken links"
    [ $FIXED_COUNTS -gt 0 ] && echo "  - $FIXED_COUNTS count mismatches"
    echo ""
    echo "Run without --dry-run to apply fixes"
elif [ "$AUTO_FIX" = false ]; then
    if [ $TOTAL_ISSUES -eq 0 ]; then
        echo -e "${GREEN}✓ No documentation drift detected!${NC}"
    else
        echo -e "${RED}Documentation drift detected:${NC}"
        [ ${#ORPHANED_FILES[@]} -gt 0 ] && echo "  - ${#ORPHANED_FILES[@]} orphaned files"
        [ ${#BROKEN_LINKS[@]} -gt 0 ] && echo "  - ${#BROKEN_LINKS[@]} broken links"
        echo ""
        echo "Run without --no-fix to auto-fix these issues"
        exit 1
    fi
else
    if [ $TOTAL_FIXED -gt 0 ]; then
        echo -e "${GREEN}✓ Fixed $TOTAL_FIXED issues:${NC}"
        [ $FIXED_ORPHANS -gt 0 ] && echo "  - Added $FIXED_ORPHANS orphaned files to current.md"
        [ $FIXED_BROKEN -gt 0 ] && echo "  - Commented out $FIXED_BROKEN broken links"
        [ $FIXED_COUNTS -gt 0 ] && echo "  - Updated $FIXED_COUNTS counts"
        echo ""
        echo -e "${YELLOW}Please review and update descriptions in current.md${NC}"
    else
        echo -e "${GREEN}✓ No documentation drift detected!${NC}"
    fi
fi