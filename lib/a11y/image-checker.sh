#!/usr/bin/env bash
# Image accessibility checker module
# Validates alt text and image accessibility compliance

set -euo pipefail

# Check for missing alt text on images
check_image_alt_text() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check markdown images ![alt](src)
        if [[ "$line" == *"!["*"]("*")"* ]]; then
            # Extract alt text using parameter expansion (bash 3.2 compatible)
            local temp="${line#*![}"
            local alt_text="${temp%%]*}"

            if [[ -z "$alt_text" ]]; then
                log_error "$file" "$line_num" "IMG-ALT" "Image missing alt text"
            elif [[ "$alt_text" == "image" ]] || [[ "$alt_text" == "img" ]]; then
                log_warning "$file" "$line_num" "IMG-ALT-GENERIC" "Generic alt text '$alt_text' is not descriptive"
            elif [[ ${#alt_text} -gt 150 ]]; then
                log_warning "$file" "$line_num" "IMG-ALT-LONG" "Alt text exceeds 150 characters (${#alt_text} chars)"
            fi
        fi

        # Check HTML images
        if [[ "$line" == *"<img"* ]]; then
            if [[ ! "$line" == *"alt="* ]]; then
                log_error "$file" "$line_num" "IMG-ALT-HTML" "HTML image missing alt attribute"
            elif [[ "$line" == *'alt=""'* ]] || [[ "$line" == *"alt=''"* ]]; then
                log_warning "$file" "$line_num" "IMG-ALT-EMPTY" "HTML image has empty alt attribute"
            fi
        fi
    done < "$file"
}

# Check for decorative images marked appropriately
check_decorative_images() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for decorative image patterns
        if [[ "$line" == *"role=\"presentation\""* ]] || [[ "$line" == *"aria-hidden=\"true\""* ]]; then
            if [[ "$line" == *"alt="* ]] && [[ ! "$line" == *'alt=""'* ]]; then
                log_warning "$file" "$line_num" "IMG-DECORATIVE" "Decorative image should have empty alt text"
            fi
        fi
    done < "$file"
}

# Check image file format accessibility
check_image_formats() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Extract image sources
        if [[ "$line" =~ \!\[.*\]\((.*)\) ]] || [[ "$line" =~ src=[\"\'](.*?)[\"\'] ]]; then
            local img_src="${BASH_REMATCH[1]}"

            # Check for text-heavy images
            if [[ "$img_src" =~ \.(jpg|jpeg|png)$ ]]; then
                if [[ "$img_src" =~ (screenshot|text|diagram|chart|graph) ]]; then
                    log_info "$file" "$line_num" "IMG-FORMAT" "Consider using SVG for text-heavy image: $img_src"
                fi
            fi

            # Warn about animated formats
            if [[ "$img_src" =~ \.gif$ ]]; then
                log_warning "$file" "$line_num" "IMG-ANIMATED" "Animated GIF detected - ensure it has play/pause controls"
            fi
        fi
    done < "$file"
}

# Check image contrast and visibility
check_image_contrast() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for images with text overlay indicators
        if [[ "$line" =~ class=.*overlay|text-on-image ]]; then
            log_info "$file" "$line_num" "IMG-CONTRAST" "Image with text overlay - ensure sufficient contrast"
        fi
    done < "$file"
}

# Main image accessibility check
check_images_accessibility() {
    local file="$1"

    check_image_alt_text "$file"
    check_decorative_images "$file"
    check_image_formats "$file"
    check_image_contrast "$file"
}

# Export functions
export -f check_image_alt_text
export -f check_decorative_images
export -f check_image_formats
export -f check_image_contrast
export -f check_images_accessibility