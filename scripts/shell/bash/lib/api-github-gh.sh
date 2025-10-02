#!/usr/bin/env bash

# Safe options set
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

# Detect the shell and run mode
__DAQ_GH_API_SHELL="unknown"
if [[ -n "${BASH_VERSION:-}" ]]; then
    __DAQ_GH_API_SHELL="bash"
    __DAQ_GH_API_SHELL_VERSION="${BASH_VERSION}"
    # Check whether the source mode is used for bash
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
    # Check whether the source mode is used for zsh
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
__DAQ_GH_API_PATTERN=""
__DAQ_GH_API_GITHUB_REPO="${OPENDAQ_GH_API_GITHUB_REPO:-}"
__DAQ_GH_API_CACHE_DIR="${OPENDAQ_GH_API_CACHE_DIR:-${TMPDIR:-${TEMP:-${TMP:-/tmp}}}}"
__DAQ_GH_API_CACHE_DIR_RESPONSE="${__DAQ_GH_API_CACHE_DIR/response}"
__DAQ_GH_API_CACHE_DIR_ERROR="${__DAQ_GH_API_CACHE_DIR/error}"

# ------------------------------------------------------------------------------
# Compatibility helpers
# ------------------------------------------------------------------------------

# Safe comparison for older bash versions
__daq_api_gh_regex_match() {
    local string="$1"
    local pattern="$2"
    
    # The bash 3.2 (on macOS) - simply use grep
    echo "$string" | grep -qE "$pattern"
}

# ------------------------------------------------------------------------------
# Private help functions
# ------------------------------------------------------------------------------

__DAQ_GH_API_HELP_EXAMPLE_REPO="openDAQ/openDAQ"
__DAQ_GH_API_HELP_EXAMPLE_VERSION="v3.20.4"
__DAQ_GH_API_HELP_EXAMPLE_PATTERN="*linux*amd64*"

__daq_api_gh_help() {
    cat <<EOF
Usage: api-github-gh OWNER/REPO [OPTIONS]

OPTIONS:
    --version VERSION    Check specific version (default: latest)
    --list-versions      List all available versions
    --list-assets        List assets for a version
    --download-asset     Download assets for a version
    --pattern PATTERN    Filter assets by pattern (glob-style)
    --output-dir DIR     Output directory for downloads (required with --download-asset)
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
    
    # List assets for latest version
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --list-assets
    
    # List assets for specific version
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --list-assets --version ${__DAQ_GH_API_HELP_EXAMPLE_VERSION}
    
    # Filter assets by pattern
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --list-assets --version ${__DAQ_GH_API_HELP_EXAMPLE_VERSION} --pattern "${__DAQ_GH_API_HELP_EXAMPLE_PATTERN}"    # Download all assets for latest version
    
    # Download all assets for latest version
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --download-asset --output-dir ./downloads

    # Download specific version assets
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --download-asset --version ${__DAQ_GH_API_HELP_EXAMPLE_VERSION} --output-dir ./downloads/${__DAQ_GH_API_HELP_EXAMPLE_VERSION}
    
    # Download filtered assets
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --download-asset --pattern "*ubuntu*" --output-dir ./downloads/ubuntu-builds

ENVIRONMENT:
    OPENDAQ_GH_API_DEBUG=1          Enable debug output
    OPENDAQ_GH_API_GITHUB_REPO      Set the default GitHub repo
    OPENDAQ_GH_API_CACHE_DIR=/tmp   Temp dir to store intermediate cache responses

Shell: ${__DAQ_GH_API_SHELL} ${__DAQ_GH_API_SHELL_VERSION}
EOF
}

# ------------------------------------------------------------------------------
# Private logging functions (compatible with bash 3.2 and zsh)
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

# ------------------------------------------------------------------------------
# Asset functions
# ------------------------------------------------------------------------------

# List all assets for a specific version
daq_api_gh_assets_list() {
    local version="${1:-}"
    
    if [[ -z "$version" ]]; then
        __daq_api_gh_error "Version not specified for assets list"
        return 1
    fi
    
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/releases/tags/${version}"
    local temp_file="${__DAQ_GH_API_CACHE_DIR_RESPONSE}/gh_response_$$"
    
    __daq_api_gh_info "Listing assets for ${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO} version $version"
    
    # Get release data
    if ! daq_api_gh_request "$endpoint" > "$temp_file"; then
        rm -f "$temp_file"
        __daq_api_gh_error "Failed to get release data for version $version"
        return 1
    fi
    
    # Extract asset names
    local assets
    assets=$(jq -r '.assets[]? | .name // empty' < "$temp_file" 2>/dev/null)
    local exit_code=$?
    rm -f "$temp_file"
    
    if [[ -z "$assets" ]]; then
        __daq_api_gh_debug "No assets found for version $version"
        return 1
    fi
    
    echo "$assets"
    return $exit_code
}

# Filter assets by pattern
daq_api_gh_assets_filter() {
    local version="${1:-}"
    local pattern="${2:-}"
    
    if [[ -z "$version" ]]; then
        __daq_api_gh_error "Version not specified for assets filter"
        return 1
    fi
    
    if [[ -z "$pattern" ]]; then
        __daq_api_gh_error "Pattern not specified for assets filter"
        return 1
    fi
    
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/releases/tags/${version}"
    local temp_file="${__DAQ_GH_API_CACHE_DIR_RESPONSE}/gh_response_$$"
    
    __daq_api_gh_info "Filtering assets for ${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO} version $version with pattern: $pattern"
    
    # Get release data
    if ! daq_api_gh_request "$endpoint" > "$temp_file"; then
        rm -f "$temp_file"
        __daq_api_gh_error "Failed to get release data for version $version"
        return 1
    fi
    
    # Convert glob pattern to regex for jq
    # Simple conversion: * -> .*, ? -> .
    local jq_pattern
    jq_pattern=$(echo "$pattern" | sed 's/\*/\.\*/g' | sed 's/?/\./g')
    
    # Filter asset names using jq with regex
    local filtered_assets
    filtered_assets=$(jq -r --arg pattern "$jq_pattern" '.assets[]? | select(.name | test($pattern)) | .name' < "$temp_file" 2>/dev/null)
    local exit_code=$?
    rm -f "$temp_file"
    
    if [[ -z "$filtered_assets" ]]; then
        __daq_api_gh_debug "No assets matching pattern '$pattern' for version $version"
        return 1
    fi
    
    echo "$filtered_assets"
    return $exit_code
}

# Get download URLs for assets
daq_api_gh_assets_urls() {
    local version="${1:-}"
    local pattern="${2:-}"
    
    if [[ -z "$version" ]]; then
        __daq_api_gh_error "Version not specified for assets URLs"
        return 1
    fi
    
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/releases/tags/${version}"
    local temp_file="${__DAQ_GH_API_CACHE_DIR_RESPONSE}/gh_response_$$"
    
    __daq_api_gh_info "Getting asset URLs for ${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO} version $version"
    
    # Get release data
    if ! daq_api_gh_request "$endpoint" > "$temp_file"; then
        rm -f "$temp_file"
        __daq_api_gh_error "Failed to get release data for version $version"
        return 1
    fi
    
    # Build jq query based on pattern
    local jq_query
    if [[ -n "$pattern" ]]; then
        # Convert glob pattern to regex
        local jq_pattern
        jq_pattern=$(echo "$pattern" | sed 's/\*/\.\*/g' | sed 's/?/\./g')
        jq_query=".assets[]? | select(.name | test(\"$jq_pattern\")) | .browser_download_url"
    else
        jq_query='.assets[]? | .browser_download_url'
    fi
    
    # Extract URLs
    local urls
    urls=$(jq -r "$jq_query" < "$temp_file" 2>/dev/null)
    local exit_code=$?
    rm -f "$temp_file"
    
    if [[ -z "$urls" ]]; then
        if [[ -n "$pattern" ]]; then
            __daq_api_gh_debug "No assets matching pattern '$pattern' for version $version"
        else
            __daq_api_gh_debug "No assets found for version $version"
        fi
        return 1
    fi
    
    echo "$urls"
    return $exit_code
}

# ------------------------------------------------------------------------------
# Download functions
# ------------------------------------------------------------------------------

# Download single asset
__daq_api_gh_download_asset() {
    local download_url="$1"
    local output_path="$2"
    local filename="${output_path##*/}"
    
    __daq_api_gh_info "Downloading: $filename"
    
    # Use gh api to download (it handles auth automatically)
    if gh api -H "Accept: application/octet-stream" "$download_url" > "$output_path" 2>/dev/null; then
        __daq_api_gh_debug "Successfully downloaded: $filename"
        return 0
    else
        __daq_api_gh_error "Failed to download: $filename"
        # Clean up partial download
        rm -f "$output_path"
        return 1
    fi
}

# Download assets for a version
daq_api_gh_assets_download() {
    local version="${1:-}"
    local output_dir="${2:-}"
    local pattern="${3:-}"
    
    # Validate inputs
    if [[ -z "$version" ]]; then
        __daq_api_gh_error "Version not specified for download"
        return 1
    fi
    
    if [[ -z "$output_dir" ]]; then
        __daq_api_gh_error "--output-dir is required for --download-asset"
        return 1
    fi
    
    # Create output directory if it doesn't exist
    if [[ ! -d "$output_dir" ]]; then
        __daq_api_gh_info "Creating directory: $output_dir"
        if ! mkdir -p "$output_dir"; then
            __daq_api_gh_error "Cannot create directory: $output_dir"
            return 1
        fi
    fi
    
    # Check write permissions
    if [[ ! -w "$output_dir" ]]; then
        __daq_api_gh_error "Cannot write to directory: $output_dir"
        return 1
    fi
    
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/releases/tags/${version}"
    local temp_file="/tmp/gh_response_$$"
    
    __daq_api_gh_info "Getting assets for ${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO} version $version"
    
    # Get release data
    if ! daq_api_gh_request "$endpoint" > "$temp_file"; then
        rm -f "$temp_file"
        __daq_api_gh_error "Failed to get release data for version $version"
        return 1
    fi
    
    # Build jq query based on pattern
    local jq_query
    if [[ -n "$pattern" ]]; then
        # Convert glob pattern to regex
        local jq_pattern
        jq_pattern=$(echo "$pattern" | sed 's/\*/\.\*/g' | sed 's/?/\./g')
        jq_query=".assets[]? | select(.name | test(\"$jq_pattern\")) | {name: .name, url: .browser_download_url}"
    else
        jq_query='.assets[]? | {name: .name, url: .browser_download_url}'
    fi
    
    # Get assets to download
    local assets_json
    assets_json=$(jq -c "$jq_query" < "$temp_file" 2>/dev/null)
    rm -f "$temp_file"
    
    if [[ -z "$assets_json" ]]; then
        if [[ -n "$pattern" ]]; then
            __daq_api_gh_info "No assets matching pattern '$pattern' for version $version"
        else
            __daq_api_gh_info "No assets found for version $version"
        fi
        return 0
    fi
    
    # Download each asset
    local download_count=0
    local error_count=0
    
    while IFS= read -r asset; do
        local name=$(echo "$asset" | jq -r '.name')
        local url=$(echo "$asset" | jq -r '.url')
        local output_path="${output_dir}/${name}"
        
        # Check if file already exists
        if [[ -f "$output_path" ]]; then
            __daq_api_gh_error "File already exists: $output_path"
            ((error_count++))
            continue
        fi
        
        # Download the asset
        if __daq_api_gh_download_asset "$url" "$output_path"; then
            download_count=$((download_count + 1))
        else
            error_count=$((error_count + 1))
        fi
    done <<< "$assets_json"
    
    # Summary
    if [[ $download_count -gt 0 ]]; then
        echo "Downloaded $download_count file(s) to $output_dir"
    fi
    
    if [[ $error_count -gt 0 ]]; then
        __daq_api_gh_error "Failed to download $error_count file(s)"
        return 1
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# Main function
# ------------------------------------------------------------------------------

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
            --list-assets)
                action="list-assets"
                shift
                ;;
            --download-asset)
                action="download-asset"
                shift
                ;;
            --pattern)
                if [[ $# -lt 2 ]]; then
                    __daq_api_gh_error "Option --pattern requires an argument"
                    return 1
                fi
                __DAQ_GH_API_PATTERN="$2"
                shift 2
                ;;
            --output-dir)
                if [[ $# -lt 2 ]]; then
                    __daq_api_gh_error "Option --output-dir requires an argument"
                    return 1
                fi
                __DAQ_GH_API_OUTPUT_DIR="$2"
                shift 2
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
    
    # Execute action
    case "$action" in
        version)
            __DAQ_GH_API_VERSION="${__DAQ_GH_API_VERSION:-latest}"
            daq_api_gh_version_resolve "$__DAQ_GH_API_VERSION"
            ;;
        list-versions)
            daq_api_gh_version_list "$limit"
            ;;
        list-assets)
            # Resolve version if needed
            __DAQ_GH_API_VERSION="${__DAQ_GH_API_VERSION:-latest}"
            if [[ "$__DAQ_GH_API_VERSION" == "latest" ]]; then
                __DAQ_GH_API_VERSION=$(daq_api_gh_version_latest) || return 1
            fi
            
            # List or filter assets
            if [[ -n "$__DAQ_GH_API_PATTERN" ]]; then
                daq_api_gh_assets_filter "$__DAQ_GH_API_VERSION" "$__DAQ_GH_API_PATTERN"
            else
                daq_api_gh_assets_list "$__DAQ_GH_API_VERSION"
            fi
            ;;
        download-asset)
            # Check required --output-dir
            if [[ -z "$__DAQ_GH_API_OUTPUT_DIR" ]]; then
                __daq_api_gh_error "--output-dir is required for --download-asset"
                return 1
            fi
            
            # Resolve version if needed
            __DAQ_GH_API_VERSION="${__DAQ_GH_API_VERSION:-latest}"
            if [[ "$__DAQ_GH_API_VERSION" == "latest" ]]; then
                __DAQ_GH_API_VERSION=$(daq_api_gh_version_latest) || return 1
            fi
            
            # Download assets
            daq_api_gh_assets_download "$__DAQ_GH_API_VERSION" "$__DAQ_GH_API_OUTPUT_DIR" "$__DAQ_GH_API_PATTERN"
            ;;
        *)
            __daq_api_gh_error "Action not specified"
            __daq_api_gh_help
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
