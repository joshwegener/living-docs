#!/bin/bash
set -euo pipefail
# Common Path Utilities Library for living-docs
# Provides consistent path handling and validation

# Source error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/errors.sh" 2>/dev/null || true

# Get absolute path (resolves symlinks)
get_absolute_path() {
    local path="$1"

    if [[ -d "$path" ]]; then
        (cd "$path" && pwd -P)
    elif [[ -f "$path" ]]; then
        local dir
        dir=$(dirname "$path")
        local file
        file=$(basename "$path")
        (cd "$dir" && echo "$(pwd -P)/$file")
    else
        # Path doesn't exist, return normalized version
        echo "$(cd "$(dirname "$path")" 2>/dev/null && pwd -P)/$(basename "$path")" || echo "$path"
    fi
}

# Get relative path from one path to another
get_relative_path() {
    local from="$1"
    local to="$2"

    # Make paths absolute
    from=$(get_absolute_path "$from")
    to=$(get_absolute_path "$to")

    # Find common prefix
    local common_part="$from"
    local result=""

    while [[ "${to#"$common_part"}" == "$to" ]]; do
        common_part=$(dirname "$common_part")
        if [[ -z "$result" ]]; then
            result=".."
        else
            result="../$result"
        fi
    done

    if [[ "$common_part" == "/" ]]; then
        result="$to"
    else
        local forward_part="${to#"$common_part"}"
        if [[ -n "$result" ]] && [[ -n "$forward_part" ]]; then
            result="$result${forward_part#/}"
        elif [[ -n "$forward_part" ]]; then
            result="${forward_part#/}"
        fi
    fi

    echo "${result:-.}"
}

# Sanitize path (remove dangerous characters)
sanitize_path() {
    local path="$1"

    # Remove leading/trailing whitespace
    path=$(echo "$path" | xargs)

    # Remove dangerous characters but keep path separators
    path=$(echo "$path" | tr -cd '[:alnum:]/_.-')

    # Remove double slashes
    path=$(echo "$path" | sed 's|//|/|g')

    # Remove leading dots that could escape directory
    path=$(echo "$path" | sed 's|^\.\./||g')

    echo "$path"
}

# Check if path is safe (no traversal)
is_safe_path() {
    local path="$1"
    local base_dir="${2:-$(pwd)}"

    # Resolve to absolute paths
    local abs_path
    abs_path=$(get_absolute_path "$path")
    local abs_base
    abs_base=$(get_absolute_path "$base_dir")

    # Check if path is within base directory
    if [[ "$abs_path" == "$abs_base"* ]]; then
        return 0
    else
        return 1
    fi
}

# Validate path exists and is accessible
validate_path() {
    local path="$1"
    local type="${2:-any}" # file, dir, or any

    case "$type" in
        file)
            [[ -f "$path" ]] || die "File not found: $path" "$E_FILE_NOT_FOUND"
            [[ -r "$path" ]] || die "Cannot read file: $path" "$E_PERMISSION_DENIED"
            ;;
        dir)
            [[ -d "$path" ]] || die "Directory not found: $path" "$E_FILE_NOT_FOUND"
            [[ -r "$path" ]] || die "Cannot read directory: $path" "$E_PERMISSION_DENIED"
            ;;
        any)
            [[ -e "$path" ]] || die "Path not found: $path" "$E_FILE_NOT_FOUND"
            [[ -r "$path" ]] || die "Cannot read path: $path" "$E_PERMISSION_DENIED"
            ;;
        *)
            die "Invalid path type: $type" "$E_INVALID_INPUT"
            ;;
    esac
}

# Create directory with parents if needed
ensure_dir() {
    local dir="$1"
    local mode="${2:-755}"

    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || die "Failed to create directory: $dir" "$E_PERMISSION_DENIED"
        chmod "$mode" "$dir" || warn "Failed to set permissions on: $dir"
    fi
}

# Get project root (git repository root or current directory)
get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# Get documentation directory
get_docs_dir() {
    local project_root
    project_root=$(get_project_root)

    # Check for .living-docs.config
    if [[ -f "$project_root/.living-docs.config" ]]; then
        # shellcheck source=/dev/null
        source "$project_root/.living-docs.config"
        echo "${docs_path:-$project_root/docs}"
    else
        echo "$project_root/docs"
    fi
}

# Find file in standard locations
find_in_standard_locations() {
    local filename="$1"
    local locations=("${@:2}")

    # Default locations if none provided
    if [[ ${#locations[@]} -eq 0 ]]; then
        locations=(
            "$(pwd)"
            "$(get_project_root)"
            "$(get_docs_dir)"
            "$HOME/.living-docs"
            "/etc/living-docs"
        )
    fi

    for location in "${locations[@]}"; do
        local path="$location/$filename"
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

# Check if path is a symlink
is_symlink() {
    local path="$1"
    [[ -L "$path" ]]
}

# Resolve symlink
resolve_symlink() {
    local path="$1"

    if [[ -L "$path" ]]; then
        readlink -f "$path" 2>/dev/null || readlink "$path"
    else
        echo "$path"
    fi
}

# Get file extension
get_extension() {
    local path="$1"
    local filename
    filename=$(basename "$path")

    case "$filename" in
        *.*)
            echo "${filename##*.}"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Get filename without extension
get_basename_no_ext() {
    local path="$1"
    local filename
    filename=$(basename "$path")

    case "$filename" in
        *.*)
            echo "${filename%.*}"
            ;;
        *)
            echo "$filename"
            ;;
    esac
}

# Export functions
export -f get_absolute_path
export -f get_relative_path
export -f sanitize_path
export -f is_safe_path
export -f validate_path
export -f ensure_dir
export -f get_project_root
export -f get_docs_dir
export -f find_in_standard_locations
export -f is_symlink
export -f resolve_symlink
export -f get_extension
export -f get_basename_no_ext