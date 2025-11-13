#!/usr/bin/env bash
# api-github-gh.sh - GitHub API wrapper for working with releases
# Supports listing and resolving release versions
# Compatible with bash 3.2+ and zsh

# Exit on undefined variables
set -u

__DAQ_GH_API_SHELL="unknown"
if [[ -n "${BASH_VERSION:-}" ]]; then
    __DAQ_GH_API_SHELL="bash"
    __DAQ_GH_API_SHELL_VERSION="${BASH_VERSION}"
    # Check if sourced (BASH_SOURCE available since Bash 3.0)
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        __DAQ_GH_API_SOURCED=1
    else
        __DAQ_GH_API_SOURCED=0
    fi
    # Enable pipefail for Bash 4+ (not available in Bash 3.2)
    if [[ "${BASH_VERSINFO:-0}" -ge 4 ]]; then
        set -o pipefail
    fi
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    __DAQ_GH_API_SHELL="zsh"
    __DAQ_GH_API_SHELL_VERSION="${ZSH_VERSION}"
    # Check if sourced in Zsh
    if [[ "${ZSH_EVAL_CONTEXT:-}" == *:file ]]; then
        __DAQ_GH_API_SOURCED=1
    else
        __DAQ_GH_API_SOURCED=0
    fi

    setopt PIPE_FAIL 2>/dev/null || true  # Zsh equivalent of pipefail
else
    # Unknown shell, assume not sourced
    __DAQ_GH_API_SOURCED=0
fi

# Public variables
OPENDAQ_GH_API_DEBUG="${OPENDAQ_GH_API_DEBUG:-0}"
OPENDAQ_GH_API_INITIALIZED=0

# Private variables
__DAQ_GH_API_VERBOSE=0
__DAQ_GH_API_REPO=""
__DAQ_GH_API_OWNER=""
__DAQ_GH_API_VERSION=""

__DAQ_GH_API_GITHUB_REPO="${OPENDAQ_GH_API_GITHUB_REPO:-}"
__DAQ_GH_API_CACHE_DIR="${OPENDAQ_GH_API_CACHE_DIR:-${TMPDIR:-${TEMP:-${TMP:-/tmp}}}}"
__DAQ_GH_API_CACHE_DIR_RESPONSE="${__DAQ_GH_API_CACHE_DIR/response}"
__DAQ_GH_API_CACHE_DIR_ERROR="${__DAQ_GH_API_CACHE_DIR/error}"

# Safe comparison for older bash versions
__daq_api_gh_regex_match() {
    local string="$1"
    local pattern="$2"
    
    # The bash 3.2 (on macOS) - simply use grep
    echo "$string" | grep -qE "$pattern"
}

__DAQ_GH_API_HELP_EXAMPLE_REPO="openDAQ/openDAQ"
__DAQ_GH_API_HELP_EXAMPLE_VERSION="v3.20.4"

__daq_api_gh_help() {
    cat <<EOF
Usage: api-github-gh OWNER/REPO [OPTIONS]

OPTIONS:
    --version VERSION    Check specific version (default: latest)
    --list-versions      List all available versions
    --limit N            Limit number of versions (default: 30, use 'all' for all)
    --verbose            Enable verbose output
    --help               Show this help

EXAMPLES:
    # Get latest version
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO}
    
    # Verify specific version
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --version ${__DAQ_GH_API_HELP_EXAMPLE_VERSION}
    
    # List all versions
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --list-versions

    # Get last 5 versions
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --list-versions --limit 5

ENVIRONMENT:
    OPENDAQ_GH_API_DEBUG=1          Enable debug output
    OPENDAQ_GH_API_GITHUB_REPO      Set the default GitHub repo
    OPENDAQ_GH_API_CACHE_DIR=/tmp   Temp dir to store intermediate cache responses

Shell: ${__DAQ_GH_API_SHELL} ${__DAQ_GH_API_SHELL_VERSION}
EOF
}

__daq_api_gh_error() {
    echo "❌ $*" >&2
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

# Generic API request wrapper
daq_api_gh_request() {
    local endpoint="$1"
    local temp_error="${__DAQ_GH_API_CACHE_DIR_ERROR}/gh_error_$$"
    
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

daq_api_gh_init() {
    if [[ "${OPENDAQ_GH_API_INITIALIZED}" -eq 1 ]]; then
        __daq_api_gh_debug "Already initialized"
        return 0
    fi
    
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
    
    # Use grep instead of =~ for compatibility
    if ! __daq_api_gh_regex_match "$repo" "^[^/]+/[^/]+$"; then
        __daq_api_gh_error "Invalid repository format. Expected: owner/repo"
        return 1
    fi
    
    # Safe strings separation (works for both bash 3.2 and zsh)
    __DAQ_GH_API_OWNER="${repo%%/*}"
    __DAQ_GH_API_REPO="${repo#*/}"
    
    __daq_api_gh_debug "Parsed: owner=$__DAQ_GH_API_OWNER, repo=$__DAQ_GH_API_REPO"
    return 0
}

# Get latest release version
daq_api_gh_version_latest() {
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/releases/latest"
    local temp_file="${__DAQ_GH_API_CACHE_DIR_RESPONSE}/gh_response_$$"
    
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
    local temp_file="${__DAQ_GH_API_CACHE_DIR_RESPONSE}/gh_response_$$"
    
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

__daq_api_gh_main() {
    local repo=${__DAQ_GH_API_GITHUB_REPO}
    local action=""
    local limit="30"
    local version=""
    
    # Parse arguments (POSIX-style for compatibility)
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
            --limit)
                if [[ $# -lt 2 ]]; then
                    __daq_api_gh_error "Option --limit requires an argument"
                    return 1
                fi
                limit="$2"
                shift 2
                ;;
            --verbose)
                __DAQ_GH_API_VERBOSE=1
                shift
                ;;
            --help|-h)
                __daq_api_gh_help
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
        __daq_api_gh_help
        return 1
    fi
    
    # Initialize and parse
    daq_api_gh_init || return 1
    daq_api_gh_repo_parse "$repo" || return 1

    __DAQ_GH_API_VERSION="${__DAQ_GH_API_VERSION:-latest}"
    if [[ "$__DAQ_GH_API_VERSION" == "latest" ]]; then
        __DAQ_GH_API_VERSION=$(daq_api_gh_version_latest)
    fi

    if [[ -z "$action" ]]; then
        action="version"
    fi
    
    # Execute action
    case "$action" in
        version)
            __DAQ_GH_API_VERSION="${__DAQ_GH_API_VERSION:-latest}"
            daq_api_gh_version_resolve "$__DAQ_GH_API_VERSION"
            ;;
        list-versions)
            daq_api_gh_version_list "$limit"
            ;;
        *)
            __daq_api_gh_error "Action not specified"
            __daq_api_gh_help
            ;;
    esac
}

if [[ "${__DAQ_GH_API_SOURCED}" -eq 0 ]]; then
    __daq_api_gh_main "$@"
    exit $?
fi
