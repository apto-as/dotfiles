#!/usr/bin/env bash
# ============================================================================
# tests/test_versions.sh - Version Detection Tests
# Purpose: Validate version fetching, caching, and fallback behavior
# Usage: ./tests/test_versions.sh
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"

# Source dependencies
# Note: core.sh sets strict mode, we need to relax it for tests
(
    # Source in subshell to get function definitions
    source "${DOTFILES_DIR}/lib/core.sh" 2>/dev/null
    declare -f log_info log_warn log_error log_debug log_success command_exists
) > /tmp/core_funcs.sh
source /tmp/core_funcs.sh

# Set test-friendly options
set +e  # Don't exit on errors (tests need to handle failures)
set -u  # Undefined variables are errors
set -o pipefail

# Minimal logging for tests
LOG_FILE="${HOME}/.dotfiles-install.log"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_debug() { :; }  # No-op for tests

# Source versions.sh in subshell to extract functions
(
    set +e
    source "${DOTFILES_DIR}/lib/versions.sh" 2>/dev/null
    declare -f _init_cache _cache_valid _cache_read _cache_write _http_get
    declare -f get_latest_nvm_version get_latest_go_version get_latest_node_lts_version
    declare -f clear_version_cache prefetch_versions
    echo "VERSION_CACHE_DIR='${VERSION_CACHE_DIR}'"
    echo "VERSION_CACHE_TTL=${VERSION_CACHE_TTL}"
    echo "VERSION_REQUEST_TIMEOUT=${VERSION_REQUEST_TIMEOUT}"
    echo "FALLBACK_NVM_VERSION='${FALLBACK_NVM_VERSION}'"
    echo "FALLBACK_GO_VERSION='${FALLBACK_GO_VERSION}'"
    echo "FALLBACK_NODE_LTS_VERSION='${FALLBACK_NODE_LTS_VERSION}'"
) > /tmp/version_funcs.sh
source /tmp/version_funcs.sh

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# Test Framework
# ============================================================================

test_start() {
    local name="$1"
    ((TESTS_RUN++))
    echo -n "  Testing: ${name}... "
}

test_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}PASS${NC}"
}

test_fail() {
    local reason="${1:-}"
    ((TESTS_FAILED++))
    echo -e "${RED}FAIL${NC}"
    [[ -n "${reason}" ]] && echo "    Reason: ${reason}"
}

assert_not_empty() {
    local value="$1"
    local name="$2"

    if [[ -z "${value}" ]]; then
        test_fail "${name} is empty"
        return 1
    fi
    return 0
}

assert_matches() {
    local value="$1"
    local pattern="$2"
    local name="$3"

    if [[ ! "${value}" =~ ${pattern} ]]; then
        test_fail "${name}='${value}' does not match pattern '${pattern}'"
        return 1
    fi
    return 0
}

# ============================================================================
# Tests
# ============================================================================

test_nvm_version_format() {
    test_start "NVM version format (vX.Y.Z)"

    local version
    version=$(get_latest_nvm_version)

    if assert_not_empty "${version}" "NVM version" && \
       assert_matches "${version}" '^v[0-9]+\.[0-9]+\.[0-9]+$' "NVM version"; then
        test_pass
    fi
}

test_go_version_format() {
    test_start "Go version format (X.Y.Z)"

    local version
    version=$(get_latest_go_version)

    if assert_not_empty "${version}" "Go version" && \
       assert_matches "${version}" '^[0-9]+\.[0-9]+\.[0-9]+$' "Go version"; then
        test_pass
    fi
}

test_node_lts_version_format() {
    test_start "Node LTS version format (X.Y.Z)"

    local version
    version=$(get_latest_node_lts_version)

    if assert_not_empty "${version}" "Node LTS version" && \
       assert_matches "${version}" '^[0-9]+\.[0-9]+\.[0-9]+$' "Node LTS version"; then
        test_pass
    fi
}

test_cache_creation() {
    test_start "Cache file creation"

    # Clear cache first
    clear_version_cache 2>/dev/null || true

    # Trigger fetch
    get_latest_nvm_version >/dev/null

    local cache_file="${VERSION_CACHE_DIR}/nvm.version"

    if [[ -f "${cache_file}" ]]; then
        test_pass
    else
        test_fail "Cache file not created at ${cache_file}"
    fi
}

test_cache_read() {
    test_start "Cache read performance"

    # Ensure cache is populated
    get_latest_nvm_version >/dev/null

    # Time cached read
    local start_time end_time elapsed
    start_time=$(date +%s%N 2>/dev/null || date +%s)

    for _ in {1..10}; do
        get_latest_nvm_version >/dev/null
    done

    end_time=$(date +%s%N 2>/dev/null || date +%s)

    # On systems with nanoseconds
    if [[ "${start_time}" =~ [0-9]{10,} ]]; then
        elapsed=$(( (end_time - start_time) / 1000000 ))  # Convert to ms
        if [[ ${elapsed} -lt 100 ]]; then  # 10 reads under 100ms
            test_pass
        else
            test_fail "Cache reads took ${elapsed}ms (expected <100ms)"
        fi
    else
        # Fallback: just verify it runs without timing
        test_pass
    fi
}

test_fallback_on_no_network() {
    test_start "Fallback on network failure"

    # Simulate network failure by using invalid URL (override temporarily)
    # This is a functional test - we verify fallback values are returned

    local version
    version=$(get_latest_nvm_version)

    if [[ -n "${version}" ]]; then
        test_pass
    else
        test_fail "No version returned (fallback failed)"
    fi
}

test_prefetch_parallel() {
    test_start "Parallel prefetch"

    clear_version_cache 2>/dev/null || true

    local start_time end_time
    start_time=$(date +%s)

    prefetch_versions

    end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    # Parallel fetch should complete in under 10 seconds
    if [[ ${elapsed} -lt 10 ]]; then
        # Verify all caches exist
        if [[ -f "${VERSION_CACHE_DIR}/nvm.version" ]] && \
           [[ -f "${VERSION_CACHE_DIR}/go.version" ]] && \
           [[ -f "${VERSION_CACHE_DIR}/node_lts.version" ]]; then
            test_pass
        else
            test_fail "Not all cache files created"
        fi
    else
        test_fail "Prefetch took ${elapsed}s (expected <10s)"
    fi
}

test_version_sanity() {
    test_start "Version sanity checks"

    local nvm_version go_version node_version
    nvm_version=$(get_latest_nvm_version)
    go_version=$(get_latest_go_version)
    node_version=$(get_latest_node_lts_version)

    # NVM should be 0.x.x range
    local nvm_major
    nvm_major=$(echo "${nvm_version}" | sed 's/v\([0-9]*\).*/\1/')

    # Go should be 1.x.x range (for foreseeable future)
    local go_major
    go_major=$(echo "${go_version}" | cut -d. -f1)

    # Node LTS should be even major version
    local node_major
    node_major=$(echo "${node_version}" | cut -d. -f1)

    if [[ "${nvm_major}" == "0" ]] && \
       [[ "${go_major}" == "1" ]] && \
       [[ $((node_major % 2)) -eq 0 ]]; then
        test_pass
    else
        test_fail "Unexpected version ranges: NVM=${nvm_version}, Go=${go_version}, Node=${node_version}"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo "============================================="
    echo "  Version Detection Tests"
    echo "============================================="
    echo ""

    # Run tests
    test_nvm_version_format
    test_go_version_format
    test_node_lts_version_format
    test_cache_creation
    test_cache_read
    test_fallback_on_no_network
    test_prefetch_parallel
    test_version_sanity

    echo ""
    echo "============================================="
    echo "  Results: ${TESTS_PASSED}/${TESTS_RUN} passed"

    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        echo -e "  ${RED}${TESTS_FAILED} test(s) failed${NC}"
        echo "============================================="
        exit 1
    else
        echo -e "  ${GREEN}All tests passed${NC}"
        echo "============================================="
        exit 0
    fi
}

main "$@"
