#!/usr/bin/env bash
# Path Security Library for living-docs
# Comprehensive path validation and security functions
# Prevents path traversal, symlink attacks, and other file system security issues

set -euo pipefail

# Turn off function dumping for verbose mode
set +x

# Detect path traversal attempts including encoded variants
detect_path_traversal() {
    local path="$1"

    # Check for empty path
    if [[ -z "$path" ]]; then
        return 0
    fi

    # URL decode the path multiple times to catch double/triple encoding
    local decoded="$path"
    local prev_decoded=""
    local max_iterations=5
    local iteration=0

    while [[ "$decoded" != "$prev_decoded" && $iteration -lt $max_iterations ]]; do
        prev_decoded="$decoded"
        # Decode %XX sequences
        decoded=$(printf '%b' "${decoded//%/\\x}")
        ((iteration++))
    done

    # Check for various path traversal patterns
    if [[ "$decoded" =~ \.\./ ]] || [[ "$decoded" =~ \.\.\\ ]]; then
        echo "ERROR: path traversal detected in: $path" >&2
        return 1
    fi

    # Check for Windows-style path traversal
    if [[ "$decoded" =~ \.\.\\ ]] || [[ "$decoded" =~ \.\./.* ]]; then
        echo "ERROR: path traversal detected in: $path" >&2
        return 1
    fi

    # Check for encoded dot patterns
    if [[ "$decoded" =~ %2e%2e ]] || [[ "$decoded" =~ %252e%252e ]]; then
        echo "ERROR: path traversal detected in: $path" >&2
        return 1
    fi

    return 0
}

# Validate that a path is absolute
validate_absolute_path() {
    local path="$1"

    if [[ -z "$path" ]]; then
        echo "ERROR: empty path not allowed" >&2
        return 1
    fi

    if [[ ! "$path" =~ ^/ ]]; then
        echo "ERROR: absolute path required, got: $path" >&2
        return 1
    fi

    return 0
}

# Validate that a path is relative and safe
validate_relative_path() {
    local path="$1"

    if [[ -z "$path" ]]; then
        echo "ERROR: empty path not allowed" >&2
        return 1
    fi

    if [[ "$path" =~ ^/ ]]; then
        echo "ERROR: relative path required, got: $path" >&2
        return 1
    fi

    # Check for path traversal in relative paths
    if ! detect_path_traversal "$path"; then
        echo "ERROR: path traversal not allowed in relative paths" >&2
        return 1
    fi

    return 0
}

# Normalize a path by resolving . and .. components
normalize_path() {
    local path="$1"
    local is_absolute=false

    # Check if path is absolute
    if [[ "$path" =~ ^/ ]]; then
        is_absolute=true
    fi

    # Split path into components
    local IFS='/'
    local components=($path)
    local normalized_components=()

    for component in "${components[@]}"; do
        case "$component" in
            "" | ".")
                # Skip empty components and current directory references
                continue
                ;;
            "..")
                # Handle parent directory references
                if [[ ${#normalized_components[@]} -gt 0 ]]; then
                    local last_index=$((${#normalized_components[@]} - 1))
                    if [[ "${normalized_components[$last_index]}" != ".." ]]; then
                        # Remove last component if not already at root
                        if [[ $is_absolute == true ]] || [[ ${#normalized_components[@]} -gt 1 ]] || [[ "${normalized_components[0]}" != ".." ]]; then
                            # Remove last element from array
                            normalized_components=("${normalized_components[@]:0:$last_index}")
                        fi
                    else
                        # Can't resolve .., add another one for relative paths
                        if [[ $is_absolute == false ]]; then
                            normalized_components+=("..")
                        fi
                    fi
                elif [[ $is_absolute == false ]]; then
                    # For relative paths, keep .. if we can't resolve it
                    normalized_components+=("..")
                fi
                ;;
            *)
                normalized_components+=("$component")
                ;;
        esac
    done

    # Reconstruct path
    local result=""
    if [[ $is_absolute == true ]]; then
        if [[ ${#normalized_components[@]} -gt 0 ]]; then
            result="/$(IFS=/; echo "${normalized_components[*]}")"
        else
            result="/"
        fi
    else
        if [[ ${#normalized_components[@]} -gt 0 ]]; then
            result="$(IFS=/; echo "${normalized_components[*]}")"
        else
            result="."
        fi
    fi

    echo "$result"
    return 0
}

# Safely join two paths
safe_path_join() {
    local base="$1"
    local relative="$2"

    # Handle empty relative path
    if [[ -z "$relative" ]]; then
        echo "$base"
        return 0
    fi

    # Check for path traversal in relative component
    if ! detect_path_traversal "$relative"; then
        echo "ERROR: path traversal detected in relative component" >&2
        return 1
    fi

    # Remove trailing slashes from base and leading slashes from relative
    base="${base%/}"
    relative="${relative#/}"

    # Join paths
    local joined="$base/$relative"

    # Normalize the result
    local normalized
    normalized=$(normalize_path "$joined")

    echo "$normalized"
    return 0
}

# Resolve symlinks safely with loop detection and base directory checking
resolve_symlinks() {
    local path="$1"
    local base_dir="${2:-}"
    local max_depth=10
    local current_depth=0
    local visited_paths=()
    local current_path="$path"

    # Track visited paths to detect loops
    while [[ $current_depth -lt $max_depth ]]; do
        # Check if we've seen this path before (loop detection)
        for visited in "${visited_paths[@]}"; do
            if [[ "$current_path" == "$visited" ]]; then
                echo "ERROR: symlink loop detected" >&2
                return 1
            fi
        done

        visited_paths+=("$current_path")

        # Check if it's a symlink
        if [[ -L "$current_path" ]]; then
            # Get symlink target, but handle system loop detection errors
            local target
            if ! target=$(readlink "$current_path" 2>/dev/null); then
                echo "ERROR: symlink loop detected" >&2
                return 1
            fi

            # If target is relative, make it relative to symlink's directory
            if [[ ! "$target" =~ ^/ ]]; then
                local dir
                if ! dir=$(dirname "$current_path" 2>/dev/null); then
                    echo "ERROR: symlink loop detected" >&2
                    return 1
                fi
                target="$dir/$target"
            fi

            # Normalize the target path
            target=$(normalize_path "$target")

            # If base directory is specified, check if target escapes it
            if [[ -n "$base_dir" ]]; then
                if ! is_within_base "$target" "$base_dir"; then
                    echo "ERROR: symlink escape detected - target outside base directory" >&2
                    return 1
                fi
            fi

            current_path="$target"
            ((current_depth++))
        else
            # Not a symlink, we're done
            echo "$current_path"
            return 0
        fi
    done

    echo "ERROR: symlink loop detected - maximum depth exceeded" >&2
    return 1
}

# Check if a path is within a base directory
is_within_base() {
    local path="$1"
    local base="$2"

    # Normalize both paths
    local normalized_path
    local normalized_base
    normalized_path=$(normalize_path "$path")
    normalized_base=$(normalize_path "$base")

    # If path contains symlinks, resolve them first
    if [[ -L "$path" ]]; then
        local resolved_path
        if ! resolved_path=$(resolve_symlinks "$path" "$base"); then
            echo "ERROR: path outside base directory (symlink resolution failed)" >&2
            return 1
        fi
        normalized_path=$(normalize_path "$resolved_path")
    fi

    # Add trailing slash to base for comparison
    normalized_base="${normalized_base%/}/"

    # Check if normalized path starts with normalized base
    if [[ "$normalized_path/" =~ ^"$normalized_base" ]] || [[ "$normalized_path" == "${normalized_base%/}" ]]; then
        return 0
    else
        echo "ERROR: path outside base directory" >&2
        return 1
    fi
}

# Sanitize filename by replacing dangerous characters
sanitize_filename() {
    local filename="$1"
    local sanitized="$filename"

    # Use tr to replace all dangerous characters at once
    # This includes null bytes, control chars, and path chars
    sanitized="$(printf '%s' "$sanitized" | tr '\000-\037\177/<>:"|?*\\' '_')"

    # Handle double dots by replacing with single underscore
    sanitized="${sanitized//../_}"

    echo "$sanitized"
    return 0
}

# Validate file extension against whitelist
validate_file_extension() {
    local filename="$1"
    local allowed_extensions="$2"

    # Extract extension (case insensitive)
    local extension="${filename##*.}"
    extension="$(echo "$extension" | tr '[:upper:]' '[:lower:]')"

    # Convert allowed extensions to lowercase
    local allowed_lower="$(echo "$allowed_extensions" | tr '[:upper:]' '[:lower:]')"

    # Check if extension is in the comma-separated list
    # Add commas around the allowed list for exact matching
    local padded_allowed=",$allowed_lower,"
    local padded_extension=",$extension,"

    if [[ "$padded_allowed" == *"$padded_extension"* ]]; then
        return 0
    fi

    echo "ERROR: invalid extension '$extension' not in allowed list: $allowed_extensions" >&2
    return 1
}

# Comprehensive path security check
path_security_check() {
    local path="$1"
    local base_dir="${2:-}"
    local allowed_extensions="${3:-}"

    # Check for path traversal
    if ! detect_path_traversal "$path"; then
        echo "ERROR: security violation - path traversal detected" >&2
        return 1
    fi

    # If base directory is specified, ensure path is within it
    if [[ -n "$base_dir" ]]; then
        if ! is_within_base "$path" "$base_dir"; then
            echo "ERROR: security violation - path outside base directory" >&2
            return 1
        fi
    fi

    # If allowed extensions are specified, validate the extension
    if [[ -n "$allowed_extensions" ]]; then
        local filename
        filename=$(basename "$path")
        if ! validate_file_extension "$filename" "$allowed_extensions"; then
            echo "ERROR: security violation - invalid file extension" >&2
            return 1
        fi
    fi

    return 0
}

# Functions are available after sourcing this script
# No need to export them explicitly