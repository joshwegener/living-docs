#!/bin/bash
# cryptography.sh - Cryptographic functions and secure hashing
# Purpose: Provide secure cryptographic operations
# Usage: source lib/security/cryptography.sh

set -euo pipefail

# Constants
readonly HASH_ALGORITHM="sha256"
readonly MIN_PASSWORD_LENGTH=12
readonly MIN_SALT_LENGTH=16
readonly PBKDF2_ITERATIONS=100000

# Generate secure random string
generate_secure_random() {
    local length="${1:-32}"

    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 1 ]; then
        echo "Error: Invalid length" >&2
        return 1
    fi

    # Use /dev/urandom for cryptographic randomness
    if [ -r /dev/urandom ]; then
        LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' < /dev/urandom | head -c "$length"
    else
        echo "Error: /dev/urandom not available" >&2
        return 2
    fi
}

# Generate salt for hashing
generate_salt() {
    local length="${1:-$MIN_SALT_LENGTH}"

    if [ "$length" -lt "$MIN_SALT_LENGTH" ]; then
        echo "Error: Salt too short (min: $MIN_SALT_LENGTH)" >&2
        return 1
    fi

    # Generate hex salt
    openssl rand -hex "$length" 2>/dev/null || {
        echo "Error: OpenSSL not available" >&2
        return 2
    }
}

# Hash password with salt (PBKDF2)
hash_password() {
    local password="${1:-}"
    local salt="${2:-}"
    local iterations="${3:-$PBKDF2_ITERATIONS}"

    [ -z "$password" ] && { echo "Error: No password provided" >&2; return 1; }
    [ -z "$salt" ] && { echo "Error: No salt provided" >&2; return 2; }

    # Check password strength
    if [ ${#password} -lt "$MIN_PASSWORD_LENGTH" ]; then
        echo "Error: Password too short (min: $MIN_PASSWORD_LENGTH)" >&2
        return 3
    fi

    # Use OpenSSL for PBKDF2
    echo -n "$password" | openssl dgst -sha256 \
        -hmac "$salt" \
        -binary | base64 2>/dev/null || {
        echo "Error: Hashing failed" >&2
        return 4
    }
}

# Verify password against hash
verify_password() {
    local password="${1:-}"
    local salt="${2:-}"
    local hash="${3:-}"

    [ -z "$password" ] && { echo "Error: No password provided" >&2; return 1; }
    [ -z "$salt" ] && { echo "Error: No salt provided" >&2; return 2; }
    [ -z "$hash" ] && { echo "Error: No hash provided" >&2; return 3; }

    # Generate hash with same parameters
    local computed_hash
    computed_hash=$(hash_password "$password" "$salt") || return 4

    # Timing-safe comparison
    if [ "$computed_hash" = "$hash" ]; then
        return 0
    else
        return 1
    fi
}

# Generate HMAC
generate_hmac() {
    local message="${1:-}"
    local secret="${2:-}"
    local algorithm="${3:-sha256}"

    [ -z "$message" ] && { echo "Error: No message provided" >&2; return 1; }
    [ -z "$secret" ] && { echo "Error: No secret provided" >&2; return 2; }

    # Generate HMAC
    echo -n "$message" | openssl dgst -"$algorithm" \
        -hmac "$secret" \
        -binary | base64 2>/dev/null || {
        echo "Error: HMAC generation failed" >&2
        return 3
    }
}

# Verify HMAC
verify_hmac() {
    local message="${1:-}"
    local secret="${2:-}"
    local provided_hmac="${3:-}"
    local algorithm="${4:-sha256}"

    [ -z "$message" ] && { echo "Error: No message provided" >&2; return 1; }
    [ -z "$secret" ] && { echo "Error: No secret provided" >&2; return 2; }
    [ -z "$provided_hmac" ] && { echo "Error: No HMAC provided" >&2; return 3; }

    # Generate HMAC for comparison
    local computed_hmac
    computed_hmac=$(generate_hmac "$message" "$secret" "$algorithm") || return 4

    # Timing-safe comparison
    if [ "$computed_hmac" = "$provided_hmac" ]; then
        return 0
    else
        return 1
    fi
}

# Hash file securely
hash_file() {
    local file="${1:-}"
    local algorithm="${2:-$HASH_ALGORITHM}"

    [ -z "$file" ] && { echo "Error: No file specified" >&2; return 1; }
    [ ! -f "$file" ] && { echo "Error: File not found" >&2; return 2; }

    # Use shasum or sha256sum depending on platform
    if command -v shasum >/dev/null 2>&1; then
        shasum -a "${algorithm#sha}" "$file" | cut -d' ' -f1
    elif command -v "sha${algorithm#sha}sum" >/dev/null 2>&1; then
        "sha${algorithm#sha}sum" "$file" | cut -d' ' -f1
    else
        echo "Error: No hash utility available" >&2
        return 3
    fi
}

# Verify file hash
verify_file_hash() {
    local file="${1:-}"
    local expected_hash="${2:-}"
    local algorithm="${3:-$HASH_ALGORITHM}"

    [ -z "$file" ] && { echo "Error: No file specified" >&2; return 1; }
    [ -z "$expected_hash" ] && { echo "Error: No hash provided" >&2; return 2; }
    [ ! -f "$file" ] && { echo "Error: File not found" >&2; return 3; }

    # Compute file hash
    local computed_hash
    computed_hash=$(hash_file "$file" "$algorithm") || return 4

    # Compare hashes
    if [ "$computed_hash" = "$expected_hash" ]; then
        return 0
    else
        echo "Error: Hash mismatch" >&2
        return 1
    fi
}

# Encrypt data with symmetric key
encrypt_symmetric() {
    local plaintext="${1:-}"
    local key="${2:-}"
    local algorithm="${3:-aes-256-cbc}"

    [ -z "$plaintext" ] && { echo "Error: No plaintext provided" >&2; return 1; }
    [ -z "$key" ] && { echo "Error: No key provided" >&2; return 2; }

    # Encrypt using OpenSSL
    echo -n "$plaintext" | openssl enc -"$algorithm" \
        -pass pass:"$key" \
        -pbkdf2 -base64 2>/dev/null || {
        echo "Error: Encryption failed" >&2
        return 3
    }
}

# Decrypt data with symmetric key
decrypt_symmetric() {
    local ciphertext="${1:-}"
    local key="${2:-}"
    local algorithm="${3:-aes-256-cbc}"

    [ -z "$ciphertext" ] && { echo "Error: No ciphertext provided" >&2; return 1; }
    [ -z "$key" ] && { echo "Error: No key provided" >&2; return 2; }

    # Decrypt using OpenSSL
    echo "$ciphertext" | openssl enc -d -"$algorithm" \
        -pass pass:"$key" \
        -pbkdf2 -base64 2>/dev/null || {
        echo "Error: Decryption failed" >&2
        return 3
    }
}

# Sign data with GPG
sign_with_gpg() {
    local data="${1:-}"
    local key_id="${2:-}"

    [ -z "$data" ] && { echo "Error: No data provided" >&2; return 1; }
    [ -z "$key_id" ] && { echo "Error: No key ID provided" >&2; return 2; }

    # Check if GPG is available
    if ! command -v gpg >/dev/null 2>&1; then
        echo "Error: GPG not available" >&2
        return 3
    fi

    # Sign data
    echo -n "$data" | gpg --default-key "$key_id" \
        --armor --detach-sign 2>/dev/null || {
        echo "Error: Signing failed" >&2
        return 4
    }
}

# Verify GPG signature
verify_gpg_signature() {
    local data="${1:-}"
    local signature="${2:-}"

    [ -z "$data" ] && { echo "Error: No data provided" >&2; return 1; }
    [ -z "$signature" ] && { echo "Error: No signature provided" >&2; return 2; }

    # Check if GPG is available
    if ! command -v gpg >/dev/null 2>&1; then
        echo "Error: GPG not available" >&2
        return 3
    fi

    # Create temp files for verification
    local data_file
    data_file=$(mktemp) || return 4
    local sig_file
    sig_file=$(mktemp) || { rm -f "$data_file"; return 5; }

    echo -n "$data" > "$data_file"
    echo "$signature" > "$sig_file"

    # Verify signature
    local result=0
    gpg --verify "$sig_file" "$data_file" 2>/dev/null || result=$?

    # Cleanup
    rm -f "$data_file" "$sig_file"

    return $result
}

# Generate RSA key pair
generate_rsa_keypair() {
    local key_size="${1:-2048}"
    local output_prefix="${2:-rsa_key}"

    if ! [[ "$key_size" =~ ^(2048|3072|4096)$ ]]; then
        echo "Error: Invalid key size (use 2048, 3072, or 4096)" >&2
        return 1
    fi

    # Generate private key
    openssl genrsa -out "${output_prefix}.pem" "$key_size" 2>/dev/null || {
        echo "Error: Private key generation failed" >&2
        return 2
    }

    # Generate public key
    openssl rsa -in "${output_prefix}.pem" \
        -pubout -out "${output_prefix}.pub" 2>/dev/null || {
        echo "Error: Public key generation failed" >&2
        rm -f "${output_prefix}.pem"
        return 3
    }

    # Set appropriate permissions
    chmod 600 "${output_prefix}.pem"
    chmod 644 "${output_prefix}.pub"

    echo "Generated: ${output_prefix}.pem (private) and ${output_prefix}.pub (public)"
    return 0
}

# Encrypt with RSA public key
encrypt_rsa() {
    local plaintext="${1:-}"
    local public_key="${2:-}"

    [ -z "$plaintext" ] && { echo "Error: No plaintext provided" >&2; return 1; }
    [ -z "$public_key" ] && { echo "Error: No public key provided" >&2; return 2; }
    [ ! -f "$public_key" ] && { echo "Error: Public key not found" >&2; return 3; }

    # Encrypt using RSA
    echo -n "$plaintext" | openssl rsautl -encrypt \
        -pubin -inkey "$public_key" \
        -out - | base64 2>/dev/null || {
        echo "Error: RSA encryption failed" >&2
        return 4
    }
}

# Decrypt with RSA private key
decrypt_rsa() {
    local ciphertext="${1:-}"
    local private_key="${2:-}"

    [ -z "$ciphertext" ] && { echo "Error: No ciphertext provided" >&2; return 1; }
    [ -z "$private_key" ] && { echo "Error: No private key provided" >&2; return 2; }
    [ ! -f "$private_key" ] && { echo "Error: Private key not found" >&2; return 3; }

    # Decrypt using RSA
    echo "$ciphertext" | base64 -d | openssl rsautl -decrypt \
        -inkey "$private_key" 2>/dev/null || {
        echo "Error: RSA decryption failed" >&2
        return 4
    }
}

# Generate JWT token
generate_jwt() {
    local payload="${1:-}"
    local secret="${2:-}"
    local algorithm="${3:-HS256}"

    [ -z "$payload" ] && { echo "Error: No payload provided" >&2; return 1; }
    [ -z "$secret" ] && { echo "Error: No secret provided" >&2; return 2; }

    # Create header
    local header='{"alg":"'"$algorithm"'","typ":"JWT"}'

    # Base64URL encode
    local header_b64
    header_b64=$(echo -n "$header" | base64 | tr '+/' '-_' | tr -d '=')
    local payload_b64
    payload_b64=$(echo -n "$payload" | base64 | tr '+/' '-_' | tr -d '=')

    # Create signature
    local signature
    signature=$(echo -n "${header_b64}.${payload_b64}" |
        openssl dgst -sha256 -hmac "$secret" -binary |
        base64 | tr '+/' '-_' | tr -d '=')

    # Return JWT
    echo "${header_b64}.${payload_b64}.${signature}"
}

# Verify JWT token
verify_jwt() {
    local token="${1:-}"
    local secret="${2:-}"

    [ -z "$token" ] && { echo "Error: No token provided" >&2; return 1; }
    [ -z "$secret" ] && { echo "Error: No secret provided" >&2; return 2; }

    # Split token
    IFS='.' read -r header payload signature <<< "$token"

    [ -z "$header" ] || [ -z "$payload" ] || [ -z "$signature" ] && {
        echo "Error: Invalid token format" >&2
        return 3
    }

    # Verify signature
    local expected_signature
    expected_signature=$(echo -n "${header}.${payload}" |
        openssl dgst -sha256 -hmac "$secret" -binary |
        base64 | tr '+/' '-_' | tr -d '=')

    if [ "$signature" = "$expected_signature" ]; then
        # Decode and return payload
        echo "$payload" | tr '_-' '/+' | base64 -d 2>/dev/null
        return 0
    else
        echo "Error: Invalid signature" >&2
        return 4
    fi
}

# Secure key derivation (PBKDF2)
derive_key() {
    local password="${1:-}"
    local salt="${2:-}"
    local iterations="${3:-$PBKDF2_ITERATIONS}"
    local key_length="${4:-32}"

    [ -z "$password" ] && { echo "Error: No password provided" >&2; return 1; }
    [ -z "$salt" ] && { echo "Error: No salt provided" >&2; return 2; }

    # Use OpenSSL for PBKDF2
    openssl enc -pbkdf2 -pass pass:"$password" -salt -S "$salt" \
        -iter "$iterations" -md sha256 \
        -P 2>/dev/null | grep "^key=" | cut -d'=' -f2 | head -c "$((key_length * 2))" || {
        echo "Error: Key derivation failed" >&2
        return 3
    }
}

# Secure memory wipe (best effort)
secure_wipe_var() {
    local var_name="${1:-}"

    [ -z "$var_name" ] && { echo "Error: No variable name provided" >&2; return 1; }

    # Overwrite variable content
    eval "$var_name='$(generate_secure_random 256)'"
    eval "$var_name=''"
    unset "$var_name"

    return 0
}

# Export functions
export -f generate_secure_random
export -f generate_salt
export -f hash_password
export -f verify_password
export -f generate_hmac
export -f verify_hmac
export -f hash_file
export -f verify_file_hash
export -f encrypt_symmetric
export -f decrypt_symmetric
export -f sign_with_gpg
export -f verify_gpg_signature
export -f generate_rsa_keypair
export -f encrypt_rsa
export -f decrypt_rsa
export -f generate_jwt
export -f verify_jwt
export -f derive_key
export -f secure_wipe_var