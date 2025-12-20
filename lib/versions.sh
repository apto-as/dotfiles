#!/usr/bin/env bash
# ============================================================================
# lib/versions.sh - Dynamic Version Detection
# Purpose: Fetch latest stable versions with caching and fallback
# Performance: Cache-first strategy, parallel-safe
# ============================================================================

set -euo pipefail

# Configuration
readonly VERSION_CACHE_DIR="${HOME}/.cache/dotfiles"
readonly VERSION_CACHE_TTL=3600  # 1 hour in seconds
readonly VERSION_REQUEST_TIMEOUT=5  # seconds

# Fallback versions (updated periodically)
readonly FALLBACK_NVM_VERSION="v0.40.1"
readonly FALLBACK_GO_VERSION="1.23.4"
readonly FALLBACK_NODE_LTS_VERSION="22.12.0"

# ============================================================================
# Cache Management
# ============================================================================

# Initialize cache directory
_init_cache() {
    mkdir -p "${VERSION_CACHE_DIR}"
}

# Check if cache is valid
# Args: $1 = cache file path
# Returns: 0 if valid, 1 if expired or missing
_cache_valid() {
    local cache_file="$1"

    [[ -f "${cache_file}" ]] || return 1

    local cache_mtime
    local current_time

    if [[ "${OSTYPE}" == darwin* ]]; then
        cache_mtime=$(stat -f %m "${cache_file}" 2>/dev/null) || return 1
    else
        cache_mtime=$(stat -c %Y "${cache_file}" 2>/dev/null) || return 1
    fi

    current_time=$(date +%s)
    local age=$((current_time - cache_mtime))

    [[ ${age} -lt ${VERSION_CACHE_TTL} ]]
}

# Read from cache
# Args: $1 = cache key
_cache_read() {
    local key="$1"
    local cache_file="${VERSION_CACHE_DIR}/${key}.version"

    if _cache_valid "${cache_file}"; then
        cat "${cache_file}"
        return 0
    fi
    return 1
}

# Write to cache
# Args: $1 = cache key, $2 = value
_cache_write() {
    local key="$1"
    local value="$2"

    _init_cache
    echo "${value}" > "${VERSION_CACHE_DIR}/${key}.version"
}

# ============================================================================
# HTTP Utilities
# ============================================================================

# Safe HTTP GET with timeout
# Args: $1 = URL
# Returns: Response body or empty on failure
_http_get() {
    local url="$1"

    if command -v curl &>/dev/null; then
        curl -fsSL --connect-timeout "${VERSION_REQUEST_TIMEOUT}" \
             --max-time $((VERSION_REQUEST_TIMEOUT * 2)) \
             -H "Accept: application/json" \
             "${url}" 2>/dev/null || true
    elif command -v wget &>/dev/null; then
        wget -qO- --timeout="${VERSION_REQUEST_TIMEOUT}" \
             "${url}" 2>/dev/null || true
    fi
}

# ============================================================================
# NVM Version Detection
# ============================================================================

# Get latest NVM version from GitHub releases
# Returns: Version string (e.g., "v0.40.1")
get_latest_nvm_version() {
    local cache_key="nvm"
    local cached_version

    # Check cache first
    if cached_version=$(_cache_read "${cache_key}"); then
        echo "${cached_version}"
        return 0
    fi

    # Fetch from GitHub API
    local api_url="https://api.github.com/repos/nvm-sh/nvm/releases/latest"
    local response

    response=$(_http_get "${api_url}")

    if [[ -n "${response}" ]]; then
        local version

        # Parse JSON: extract tag_name field
        if command -v jq &>/dev/null; then
            version=$(echo "${response}" | jq -r '.tag_name // empty' 2>/dev/null)
        else
            # Fallback: grep-based parsing (no jq dependency)
            version=$(echo "${response}" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | \
                      head -1 | sed 's/.*"\([^"]*\)"$/\1/')
        fi

        # Validate version format (v0.x.x)
        if [[ "${version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            _cache_write "${cache_key}" "${version}"
            echo "${version}"
            return 0
        fi
    fi

    # Fallback
    log_debug "NVM version fetch failed, using fallback: ${FALLBACK_NVM_VERSION}"
    echo "${FALLBACK_NVM_VERSION}"
}

# ============================================================================
# Go Version Detection
# ============================================================================

# Get latest stable Go version
# Returns: Version string without 'go' prefix (e.g., "1.23.4")
get_latest_go_version() {
    local cache_key="go"
    local cached_version

    # Check cache first
    if cached_version=$(_cache_read "${cache_key}"); then
        echo "${cached_version}"
        return 0
    fi

    # Fetch from go.dev API
    local api_url="https://go.dev/dl/?mode=json"
    local response

    response=$(_http_get "${api_url}")

    if [[ -n "${response}" ]]; then
        local version

        # Parse JSON: get first stable version
        if command -v jq &>/dev/null; then
            version=$(echo "${response}" | \
                      jq -r '[.[] | select(.stable == true)][0].version // empty' 2>/dev/null | \
                      sed 's/^go//')
        else
            # Fallback: regex extraction for first stable entry
            # Format: "version":"go1.23.4","stable":true
            version=$(echo "${response}" | \
                      grep -o '"version":"go[0-9.]*","stable":true' | \
                      head -1 | \
                      sed 's/.*go\([0-9.]*\)".*/\1/')
        fi

        # Validate version format (x.y.z)
        if [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            _cache_write "${cache_key}" "${version}"
            echo "${version}"
            return 0
        fi
    fi

    # Fallback
    log_debug "Go version fetch failed, using fallback: ${FALLBACK_GO_VERSION}"
    echo "${FALLBACK_GO_VERSION}"
}

# ============================================================================
# Node.js LTS Version Detection
# ============================================================================

# Get latest Node.js LTS version
# Returns: Version string (e.g., "22.12.0")
get_latest_node_lts_version() {
    local cache_key="node_lts"
    local cached_version

    # Check cache first
    if cached_version=$(_cache_read "${cache_key}"); then
        echo "${cached_version}"
        return 0
    fi

    # Fetch from Node.js API
    local api_url="https://nodejs.org/dist/index.json"
    local response

    response=$(_http_get "${api_url}")

    if [[ -n "${response}" ]]; then
        local version

        if command -v jq &>/dev/null; then
            # Get first entry where lts is not false
            version=$(echo "${response}" | \
                      jq -r '[.[] | select(.lts != false)][0].version // empty' 2>/dev/null | \
                      sed 's/^v//')
        else
            # Fallback: find first entry with lts value (not false)
            version=$(echo "${response}" | \
                      grep -o '"version":"v[0-9.]*"[^}]*"lts":"[^"]*"' | \
                      head -1 | \
                      sed 's/.*"version":"v\([0-9.]*\)".*/\1/')
        fi

        # Validate version format
        if [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            _cache_write "${cache_key}" "${version}"
            echo "${version}"
            return 0
        fi
    fi

    # Fallback
    log_debug "Node LTS version fetch failed, using fallback: ${FALLBACK_NODE_LTS_VERSION}"
    echo "${FALLBACK_NODE_LTS_VERSION}"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Clear version cache
clear_version_cache() {
    rm -rf "${VERSION_CACHE_DIR}"/*.version 2>/dev/null || true
    log_info "Version cache cleared"
}

# Display all cached versions
show_cached_versions() {
    echo "Cached versions (TTL: ${VERSION_CACHE_TTL}s):"
    echo "  NVM:  $(get_latest_nvm_version)"
    echo "  Go:   $(get_latest_go_version)"
    echo "  Node: $(get_latest_node_lts_version)"
}

# Prefetch all versions (for parallel installation prep)
prefetch_versions() {
    _init_cache

    # Parallel fetch
    get_latest_nvm_version &>/dev/null &
    local nvm_pid=$!

    get_latest_go_version &>/dev/null &
    local go_pid=$!

    get_latest_node_lts_version &>/dev/null &
    local node_pid=$!

    wait "${nvm_pid}" "${go_pid}" "${node_pid}" 2>/dev/null || true
}

# Export functions
export -f get_latest_nvm_version get_latest_go_version get_latest_node_lts_version
export -f clear_version_cache prefetch_versions
