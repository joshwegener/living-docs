#!/bin/bash

# Archive old completed work
# Moves completed work older than 30 days to archived directory

set -e

# Load config if exists
if [ -f ".living-docs.config" ]; then
    source .living-docs.config
else
    docs_path="docs"
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Archiving old completed work..."

# Create archived directory if it doesn't exist
mkdir -p "$docs_path/archived"

# Find and move files older than 30 days
archived_count=0
for file in "$docs_path/completed/"*.md; do
    if [ -f "$file" ]; then
        # Get file modification time in days
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            file_age=$(( ($(date +%s) - $(stat -f %m "$file")) / 86400 ))
        else
            # Linux
            file_age=$(( ($(date +%s) - $(stat -c %Y "$file")) / 86400 ))
        fi

        if [ $file_age -gt 30 ]; then
            filename=$(basename "$file")
            mv "$file" "$docs_path/archived/"
            echo -e "${YELLOW}→${NC} Archived: $filename (${file_age} days old)"
            ((archived_count++))
        fi
    fi
done

# Update current.md to remove archived references
if [ $archived_count -gt 0 ]; then
    echo "Updating current.md references..."

    # Create temp file
    temp_file=$(mktemp)

    # Process current.md, removing references to archived files
    while IFS= read -r line; do
        # Check if line contains reference to archived file
        skip_line=false
        for file in "$docs_path/archived/"*.md; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                if echo "$line" | grep -q "$filename"; then
                    skip_line=true
                    break
                fi
            fi
        done

        if [ "$skip_line" = false ]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$docs_path/current.md"

    # Replace current.md
    mv "$temp_file" "$docs_path/current.md"
fi

# Summary
if [ $archived_count -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No files need archiving (all work is recent)"
else
    echo -e "${GREEN}✓${NC} Archived $archived_count file(s)"
    echo -e "${GREEN}✓${NC} Updated current.md references"
fi

# Show archive stats
total_archived=$(ls "$docs_path/archived/" 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "Archive statistics:"
echo "  Total archived files: $total_archived"
echo "  Active completed work: $(ls "$docs_path/completed/" 2>/dev/null | wc -l | tr -d ' ')"