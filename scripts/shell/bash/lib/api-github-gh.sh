#!/usr/bin/env bash
# Используем env для переносимости

# Безопасная установка опций
if [[ -n "${BASH_VERSION:-}" ]]; then
    set -euo pipefail
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    set -eu
    setopt PIPE_FAIL 2>/dev/null || true
fi

# ==============================================================================
# api-github-gh - GitHub Release API wrapper using gh CLI
# Compatible with bash 3.2+ (macOS default) and zsh
# ==============================================================================

# Определение shell и режима запуска
__DAQ_GH_API_SHELL="unknown"
if [[ -n "${BASH_VERSION:-}" ]]; then
    __DAQ_GH_API_SHELL="bash"
    __DAQ_GH_API_SHELL_VERSION="${BASH_VERSION}"
    # Проверка режима source для bash
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        __DAQ_GH_API_SOURCED=1
        __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        __DAQ_GH_API_SOURCED=0
        __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    fi
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    __DAQ_GH_API_SHELL="zsh"
    __DAQ_GH_API_SHELL_VERSION="${ZSH_VERSION}"
    # Проверка режима source для zsh
    if [[ "${(%):-%N}" != "${0}" ]]; then
        __DAQ_GH_API_SOURCED=1
        __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
    else
        __DAQ_GH_API_SOURCED=0
        __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    fi
else
    __DAQ_GH_API_SOURCED=0
    __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Public variables
OPENDAQ_GH_API_VERSION="1.0.0"
OPENDAQ_GH_API_DEBUG="${OPENDAQ_GH_API_DEBUG:-0}"
OPENDAQ_GH_API_INITIALIZED=0

# Private variables
__DAQ_GH_API_VERBOSE=0
__DAQ_GH_API_REPO=""
__DAQ_GH_API_OWNER=""
__DAQ_GH_API_VERSION=""

# ------------------------------------------------------------------------------
# Compatibility helpers
# ------------------------------------------------------------------------------

# Безопасное сравнение для старых bash
__daq_api_gh_regex_match() {
    local string="$1"
    local pattern="$2"
    
    # Для bash 3.2 на macOS - используем простой grep
    echo "$string" | grep -qE "$pattern"
}

# ------------------------------------------------------------------------------
# Private logging functions (совместимы с bash 3.2 и zsh)
# ------------------------------------------------------------------------------

__daq_api_gh_log() {
    if [[ "${__DAQ_GH_API_VERBOSE}" -eq 1 ]]; then
        echo "[LOG] $*" >&2
    fi
}

__daq_api_gh_error() {
    echo "[ERROR] $*" >&2
}

__daq_api_gh_info() {
    if [[ "${__DAQ_GH_API_VERBOSE}" -eq 1 ]]; then
        echo "[INFO] $*" >&2
    fi
}

__daq_api_gh_debug() {
    if [[ "${OPENDAQ_GH_API_DEBUG}" -eq 1 ]]; then
        echo "[DEBUG] [$__DAQ_GH_API_SHELL $__DAQ_GH_API_SHELL_VERSION] $*" >&2
    fi
}

# ------------------------------------------------------------------------------
# Dependency checking (cross-platform)
# ------------------------------------------------------------------------------

__daq_api_gh_check_deps() {
    local has_error=0
    local missing_deps=""
    
    if ! command -v gh >/dev/null 2>&1; then
        missing_deps="${missing_deps}  - gh (GitHub CLI)\n"
        has_error=1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps="${missing_deps}  - jq (JSON processor)\n"
        has_error=1
    fi
    
    if [[ $has_error -eq 1 ]]; then
        __daq_api_gh_error "Missing required dependencies:"
        printf "%b" "$missing_deps" >&2
        __daq_api_gh_error ""
        __daq_api_gh_error "Installation:"
        __daq_api_gh_error "  gh: https://cli.github.com"
        __daq_api_gh_error "  jq: brew install jq (macOS) or https://jqlang.github.io/jq/"
        return 1
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# GitHub API functions
# ------------------------------------------------------------------------------

# Generic API request wrapper
daq_api_gh_request() {
    local endpoint="$1"
    local temp_error="/tmp/gh_error_$$"
    
    __daq_api_gh_debug "API request: gh api $endpoint"
    
    # Make API request and capture both stdout and stderr
    if ! gh api "$endpoint" 2>"$temp_error"; then
        local error_msg=""
        if [[ -f "$temp_error" ]]; then
            error_msg=$(cat "$temp_error")
            rm -f "$temp_error"
        fi
        
        # Parse error type
        if echo "$error_msg" | grep -q "404"; then
            __daq_api_gh_debug "Resource not found (404)"
            return 1
        elif echo "$error_msg" | grep -q "rate limit"; then
            __daq_api_gh_error "GitHub API rate limit exceeded"
            __daq_api_gh_error "Try again later or authenticate with: gh auth login"
            return 1
        elif echo "$error_msg" | grep -q "401"; then
            __daq_api_gh_error "Authentication required"
            __daq_api_gh_error "Run: gh auth login"
            return 1
        else
            __daq_api_gh_debug "API request failed: $error_msg"
            return 1
        fi
    fi
    
    rm -f "$temp_error"
    return 0
}

# ------------------------------------------------------------------------------
# Public API functions
# ------------------------------------------------------------------------------

daq_api_gh_init() {
    if [[ "${OPENDAQ_GH_API_INITIALIZED}" -eq 1 ]]; then
        __daq_api_gh_debug "Already initialized"
        return 0
    fi
    
    __daq_api_gh_debug "Initializing api-github-gh v${OPENDAQ_GH_API_VERSION}"
    __daq_api_gh_debug "Shell: ${__DAQ_GH_API_SHELL} ${__DAQ_GH_API_SHELL_VERSION}"
    
    # Check dependencies
    __daq_api_gh_check_deps || return 1
    
    # Check gh authentication
    if ! gh auth status >/dev/null 2>&1; then
        __daq_api_gh_error "GitHub CLI not authenticated"
        __daq_api_gh_error "Run: gh auth login"
        return 1
    fi
    
    OPENDAQ_GH_API_INITIALIZED=1
    __daq_api_gh_debug "Initialization complete"
    return 0
}

daq_api_gh_repo_parse() {
    local repo="${1:-}"
    
    if [[ -z "$repo" ]]; then
        __daq_api_gh_error "Repository not specified"
        return 1
    fi
    
    # Используем grep вместо =~ для совместимости
    if ! __daq_api_gh_regex_match "$repo" "^[^/]+/[^/]+$"; then
        __daq_api_gh_error "Invalid repository format. Expected: owner/repo"
        return 1
    fi
    
    # Безопасное разделение строки (работает в bash 3.2 и zsh)
    __DAQ_GH_API_OWNER="${repo%%/*}"
    __DAQ_GH_API_REPO="${repo#*/}"
    
    __daq_api_gh_debug "Parsed: owner=$__DAQ_GH_API_OWNER, repo=$__DAQ_GH_API_REPO"
    return 0
}

# Get latest release version
daq_api_gh_version_latest() {
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/releases/latest"
    local temp_file="/tmp/gh_response_$$"
    
    __daq_api_gh_info "Getting latest version for ${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}"
    
    # Get release data
    if ! daq_api_gh_request "$endpoint" > "$temp_file"; then
        rm -f "$temp_file"
        __daq_api_gh_debug "No releases found or repository doesn't exist"
        return 1
    fi
    
    # Extract tag_name using jq
    local tag_name
    tag_name=$(jq -r '.tag_name // empty' < "$temp_file" 2>/dev/null)
    rm -f "$temp_file"
    
    if [[ -z "$tag_name" ]]; then
        __daq_api_gh_error "Could not extract tag_name from response"
        return 1
    fi
    
    __daq_api_gh_info "Latest version: $tag_name"
    echo "$tag_name"
    return 0
}

# Verify if specific version exists
daq_api_gh_version_verify() {
    local version="${1:-}"
    
    if [[ -z "$version" ]]; then
        __daq_api_gh_error "Version not specified"
        return 1
    fi
    
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/releases/tags/${version}"
    
    __daq_api_gh_info "Verifying version $version for ${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}"
    
    if daq_api_gh_request "$endpoint" >/dev/null 2>&1; then
        __daq_api_gh_info "Version $version exists"
        return 0
    else
        __daq_api_gh_info "Version $version not found"
        return 1
    fi
}

# Resolve version (latest or verify specific)
daq_api_gh_version_resolve() {
    local version="${1:-latest}"
    
    __daq_api_gh_debug "Resolving version: $version"
    
    if [[ "$version" == "latest" ]]; then
        if ! daq_api_gh_version_latest; then
            __daq_api_gh_error "Failed to get latest version"
            return 1
        fi
    else
        if daq_api_gh_version_verify "$version"; then
            echo "$version"
            return 0
        else
            __daq_api_gh_error "Version $version not found"
            return 1
        fi
    fi
}

# List all versions (limit supported)
daq_api_gh_version_list() {
    local limit="${1:-30}"
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/releases"
    local temp_file="/tmp/gh_response_$$"
    
    __daq_api_gh_info "Listing versions for ${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}"
    
    # Adjust endpoint based on limit
    if [[ "$limit" != "all" ]]; then
        endpoint="${endpoint}?per_page=${limit}"
    fi
    
    # Get releases
    if ! daq_api_gh_request "$endpoint" > "$temp_file"; then
        rm -f "$temp_file"
        __daq_api_gh_error "Failed to get releases"
        return 1
    fi
    
    # Extract tag names
    jq -r '.[] | .tag_name // empty' < "$temp_file" 2>/dev/null
    local exit_code=$?
    rm -f "$temp_file"
    
    return $exit_code
}

# ------------------------------------------------------------------------------
# Main function
# ------------------------------------------------------------------------------

__daq_api_gh_main() {
    local repo=""
    local action="version"  # default action
    
    # Parse arguments (POSIX-style для совместимости)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                if [[ $# -lt 2 ]]; then
                    __daq_api_gh_error "Option --version requires an argument"
                    return 1
                fi
                __DAQ_GH_API_VERSION="$2"
                shift 2
                ;;
            --list-versions)
                action="list-versions"
                shift
                ;;
            --verbose)
                __DAQ_GH_API_VERBOSE=1
                shift
                ;;
            --help|-h)
                cat <<EOF
Usage: api-github-gh OWNER/REPO [OPTIONS]

OPTIONS:
    --version VERSION    Check specific version (default: latest)
    --list-versions      List all available versions
    --verbose           Enable verbose output
    --help              Show this help

EXAMPLES:
    api-github-gh cli/cli                    # Get latest version
    api-github-gh cli/cli --version v2.45.0  # Verify specific version
    api-github-gh cli/cli --list-versions    # List all versions

Shell: ${__DAQ_GH_API_SHELL} ${__DAQ_GH_API_SHELL_VERSION}
EOF
                return 0
                ;;
            --*)
                __daq_api_gh_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$repo" ]]; then
                    repo="$1"
                else
                    __daq_api_gh_error "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$repo" ]]; then
        __daq_api_gh_error "Repository not specified"
        return 1
    fi
    
    # Initialize and parse
    daq_api_gh_init || return 1
    daq_api_gh_repo_parse "$repo" || return 1
    
    # Execute action
    case "$action" in
        version)
            __DAQ_GH_API_VERSION="${__DAQ_GH_API_VERSION:-latest}"
            daq_api_gh_version_resolve "$__DAQ_GH_API_VERSION"
            ;;
        list-versions)
            daq_api_gh_version_list
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Entry point
# ------------------------------------------------------------------------------

if [[ "${__DAQ_GH_API_SOURCED}" -eq 0 ]]; then
    __daq_api_gh_main "$@"
    exit $?
fi
