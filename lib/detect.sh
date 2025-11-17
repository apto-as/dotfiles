#!/usr/bin/env bash
# ============================================================================
# lib/detect.sh - OS and Machine Detection
# Purpose: Detect OS, architecture, machine type
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/core.sh"

# Detect OS with caching
detect_os() {
    if [[ -n "${DETECTED_OS:-}" ]]; then
        echo "${DETECTED_OS}"
        return
    fi

    case "${OSTYPE}" in
        darwin*)
            DETECTED_OS="macos"
            ;;
        linux-gnu*)
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                DETECTED_OS="${ID}"
            else
                DETECTED_OS="linux"
            fi
            ;;
        *)
            log_error "Unsupported OS: ${OSTYPE}"
            exit 1
            ;;
    esac

    export DETECTED_OS
    echo "${DETECTED_OS}"
}

# Detect architecture
detect_arch() {
    local arch
    arch=$(uname -m)

    case "${arch}" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect machine type based on hostname
detect_machine_type() {
    local hostname
    hostname=$(hostname -s)

    # Try to match against known machines in dotfiles
    if [[ -d "${DOTFILES_DIR:-$HOME/dotfiles}/machines/${hostname}" ]]; then
        echo "${hostname}"
        return
    fi

    # Fallback: try to infer from hostname
    case "${hostname}" in
        *MacBook*|*mbp*|*MacbookPro*)
            echo "macbook"
            ;;
        *Mac*|*imac*|*Mac-mini*|*macmini*)
            echo "macmini"
            ;;
        *work*|*corp*)
            echo "work"
            ;;
        *server*|*prod*)
            echo "server"
            ;;
        *)
            echo "default"
            ;;
    esac
}

# Check if running in CI/automated environment
is_ci() {
    [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]
}

# Detect CPU cores
detect_cpu_cores() {
    if command_exists nproc; then
        nproc
    elif command_exists sysctl; then
        sysctl -n hw.ncpu
    else
        echo "2"  # Conservative fallback
    fi
}

# Detect memory in GB
detect_memory_gb() {
    if command_exists sysctl; then
        # macOS
        local mem_bytes
        mem_bytes=$(sysctl -n hw.memsize)
        echo $((mem_bytes / 1024 / 1024 / 1024))
    elif [[ -f /proc/meminfo ]]; then
        # Linux
        local mem_kb
        mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        echo $((mem_kb / 1024 / 1024))
    else
        echo "8"  # Conservative fallback
    fi
}

# Detect macOS version
detect_macos_version() {
    if [[ "$(detect_os)" == "macos" ]]; then
        sw_vers -productVersion
    else
        echo "N/A"
    fi
}

# Display system information
display_system_info() {
    local os arch machine_type cpu_cores memory_gb

    os=$(detect_os)
    arch=$(detect_arch)
    machine_type=$(detect_machine_type)
    cpu_cores=$(detect_cpu_cores)
    memory_gb=$(detect_memory_gb)

    log_info "System Information:"
    log_info "  OS: ${os} (${arch})"
    if [[ "${os}" == "macos" ]]; then
        log_info "  macOS Version: $(detect_macos_version)"
    fi
    log_info "  Machine Type: ${machine_type}"
    log_info "  CPU Cores: ${cpu_cores}"
    log_info "  Memory: ${memory_gb}GB"
    log_info "  Hostname: $(hostname -s)"
}

# Export detected values
export_system_info() {
    export DETECTED_OS="$(detect_os)"
    export DETECTED_ARCH="$(detect_arch)"
    export MACHINE_TYPE="$(detect_machine_type)"
    export CPU_CORES="$(detect_cpu_cores)"
    export MEMORY_GB="$(detect_memory_gb)"
}

# Export functions
export -f detect_os detect_arch detect_machine_type
export -f is_ci detect_cpu_cores detect_memory_gb
