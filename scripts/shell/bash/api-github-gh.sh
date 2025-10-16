#!/usr/bin/env bash
# api-github-gh.sh - GitHub API wrapper for working with releases and arifacts
# Supports downloading release / assets, resolving versions and filenames
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
        __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        __DAQ_GH_API_SOURCED=0
        __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    fi
    # Enable pipefail for Bash 4+ (not available in Bash 3.2)
    if [[ "${BASH_VERSINFO:-0}" -ge 4 ]]; then
        set -o pipefail
    fi
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    __DAQ_GH_API_SHELL="zsh"
    __DAQ_GH_API_SHELL_VERSION="${ZSH_VERSION}"
    # Check if sourced in Zsh
    # Using $0 vs ${(%):-%x} comparison (more reliable than %N)
    if [[ "${ZSH_EVAL_CONTEXT:-}" == *:file ]]; then
        __DAQ_GH_API_SOURCED=1
        __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
    else
        __DAQ_GH_API_SOURCED=0
        __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    fi

    setopt PIPE_FAIL 2>/dev/null || true  # Zsh equivalent of pipefail
else
    # Unknown shell, assume not sourced
    __DAQ_GH_API_SOURCED=0
    __DAQ_GH_API_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Public variables
OPENDAQ_GH_API_DEBUG="${OPENDAQ_GH_API_DEBUG:-0}"
OPENDAQ_GH_API_INITIALIZED=0

# Private variables
__DAQ_GH_API_VERBOSE=0
__DAQ_GH_API_REPO=""
__DAQ_GH_API_OWNER=""
__DAQ_GH_API_VERSION=""
__DAQ_GH_API_PATTERN=""
__DAQ_GH_API_RUN_ID=""
__DAQ_GH_API_EXTRACT=0

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

__daq_api_gh_normalize_path() {
    local path="$1"
    local normalized=""
    
    if [[ -z "$path" ]]; then
        echo ""
        return 0
    fi
    
    normalized="$path"
    normalized="${normalized//\\//}"
    
    if __daq_api_gh_regex_match "$normalized" "^[a-zA-Z]:"; then
        local drive="${normalized:0:1}"
        drive=$(echo "$drive" | tr '[:upper:]' '[:lower:]')
        normalized="/${drive}${normalized:2}"
    fi
    
    echo "$normalized"
}

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
    --list-runs          List latest workflow runs
    --list-artifacts     List artifacts for run-id
    --download-asset     Download assets for a version
    --pattern PATTERN    Filter assets by pattern (glob-style)
    --output-dir DIR     Output directory for downloads (required with --download-asset)
    --limit N            Limit number of versions (default: 30, use 'all' for all)
    --run-id ID          ID workflow run (mandatory)
    --extract            Extract artifacts from zip after downloading
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

    # List workflows runs
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --list-runs

    # List artifacts produced by a workflow with run ID
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --list-artifacts --run-id RUN_ID
    
    # Download all artifacts produced by a workflow with run ID
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --download-artifact --run-id RUN_ID --output-dir ./artifacts

    # Download all artifacts produced by a workflow with run ID and extract them
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --download-artifact --run-id RUN_ID --output-dir ./artifacts --extract

    # Download filterd artifacts by pattern produced by a workflow with run ID and extract them
    ./api-github-gh.sh ${__DAQ_GH_API_HELP_EXAMPLE_REPO} --download-artifact --run-id RUN_ID --pattern "*ubuntu*" --output-dir ./artifacts

ENVIRONMENT:
    OPENDAQ_GH_API_DEBUG=1          Enable debug output
    OPENDAQ_GH_API_GITHUB_REPO      Set the default GitHub repo
    OPENDAQ_GH_API_CACHE_DIR=/tmp   Temp dir to store intermediate cache responses

Shell: ${__DAQ_GH_API_SHELL} ${__DAQ_GH_API_SHELL_VERSION}
EOF
}

__daq_api_gh_log() {
    if [[ "${__DAQ_GH_API_VERBOSE}" -eq 1 ]]; then
        echo "[LOG] $*" >&2
    fi
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

daq_api_gh_artifacts_list() {
    local run_id="${1:-}"
    
    if [[ -z "$run_id" ]]; then
        __daq_api_gh_error "Run ID not specified for artifacts list"
        return 1
    fi
    
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/actions/runs/${run_id}/artifacts"
    local temp_file="/tmp/gh_response_$$"
    
    __daq_api_gh_info "Listing artifacts for run ${run_id}"
    
    if ! daq_api_gh_request "$endpoint" > "$temp_file"; then
        rm -f "$temp_file"
        __daq_api_gh_error "Failed to get artifacts for run ${run_id}"
        return 1
    fi
    
    # Output based on verbose flag
    if [[ $__DAQ_GH_API_VERBOSE -eq 1 ]]; then
        # Format: name, size in MB, expiration
        jq -r '.artifacts[] | "\(.name)\t\(.size_in_bytes/1048576 | floor)MB\t\(.expires_at)"' < "$temp_file"
    else
        # Just names
        jq -r '.artifacts[].name' < "$temp_file"
    fi
    
    rm -f "$temp_file"
}

daq_api_gh_runs_list() {
    local limit="${1:-20}"
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/actions/runs?per_page=${limit}"
    local temp_file="/tmp/gh_response_$$"
    
    __daq_api_gh_info "Listing workflow runs for ${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}"
    
    if ! daq_api_gh_request "$endpoint" > "$temp_file"; then
        rm -f "$temp_file"
        __daq_api_gh_error "Failed to get workflow runs"
        return 1
    fi
    
    # Simple output: id, status, conclusion, workflow_name
    if [[ $__DAQ_GH_API_VERBOSE -eq 1 ]]; then
        jq -r '.workflow_runs[] | "\(.id)\t\(.status)\t\(.conclusion // "pending")\t\(.name)\t\(.created_at)"' < "$temp_file"
    else
        jq -r '.workflow_runs[] | "\(.id)\t\(.name)"' < "$temp_file"
    fi
    
    rm -f "$temp_file"
}

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

__daq_api_gh_download_single_artifact() {
    local artifact_id="$1"
    local artifact_name="$2"
    local artifact_size="$3"
    local output_path="$4"
    
    # Format size for display
    local size_mb=$((artifact_size / 1048576))
    __daq_api_gh_info "Downloading artifact: $artifact_name (size: ${size_mb}MB)"
    
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/actions/artifacts/${artifact_id}/zip"
    
    # Download using gh api (follows redirects automatically)
    if gh api -H "Accept: application/vnd.github.v3+json" "$endpoint" > "$output_path" 2>/dev/null; then
        __daq_api_gh_debug "Successfully downloaded: $artifact_name"
        return 0
    else
        __daq_api_gh_error "Failed to download artifact: $artifact_name"
        rm -f "$output_path"
        return 1
    fi
}

daq_api_gh_artifacts_download() {
    local run_id="${1:-}"
    local output_dir="${2:-}"
    local pattern="${3:-}"
    local extract="${4:-0}"
    
    # Validate inputs
    if [[ -z "$run_id" ]]; then
        __daq_api_gh_error "Run ID not specified for download"
        return 1
    fi
    
    if [[ -z "$output_dir" ]]; then
        __daq_api_gh_error "--output-dir is required for --download-artifact"
        return 1
    fi
    
    # Create output directory if needed
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
    
    local endpoint="repos/${__DAQ_GH_API_OWNER}/${__DAQ_GH_API_REPO}/actions/runs/${run_id}/artifacts"
    local temp_file="/tmp/gh_response_$$"
    
    __daq_api_gh_info "Getting artifacts for run ${run_id}"
    
    if ! daq_api_gh_request "$endpoint" > "$temp_file"; then
        rm -f "$temp_file"
        __daq_api_gh_error "Failed to get artifacts for run ${run_id}"
        return 1
    fi
    
    # Build jq query based on pattern
    local jq_query
    if [[ -n "$pattern" ]]; then
        local jq_pattern
        jq_pattern=$(echo "$pattern" | sed 's/\*/\.\*/g' | sed 's/?/\./g')
        jq_query=".artifacts[] | select(.name | test(\"$jq_pattern\")) | {id: .id, name: .name, size: .size_in_bytes}"
    else
        jq_query='.artifacts[] | {id: .id, name: .name, size: .size_in_bytes}'
    fi
    
    # Get artifacts to download
    local artifacts_json
    artifacts_json=$(jq -c "$jq_query" < "$temp_file" 2>/dev/null)
    rm -f "$temp_file"
    
    if [[ -z "$artifacts_json" ]]; then
        if [[ -n "$pattern" ]]; then
            __daq_api_gh_error "No artifacts matching pattern '$pattern' for run ${run_id}"
        else
            __daq_api_gh_error "No artifacts found for run ${run_id}"
        fi
        return 1
    fi
    
    # Download each artifact
    local download_count=0
    local error_count=0
    
    echo "$artifacts_json" | while IFS= read -r artifact; do
        local id=$(echo "$artifact" | jq -r '.id')
        local name=$(echo "$artifact" | jq -r '.name')
        local size=$(echo "$artifact" | jq -r '.size')
        local output_path="${output_dir}/${name}.zip"
        
        # Check if file exists
        if [[ -f "$output_path" ]]; then
            __daq_api_gh_error "File already exists: $output_path"
            error_count=$((error_count + 1))
            continue
        fi
        
        # Download the artifact
        if __daq_api_gh_download_single_artifact "$id" "$name" "$size" "$output_path"; then
            download_count=$((download_count + 1))
            
            # Extract if requested
            if [[ $extract -eq 1 ]]; then
                __daq_api_gh_info "Extracting: $name.zip"
                if command -v unzip >/dev/null 2>&1; then
                    unzip -q "$output_path" -d "${output_dir}/${name}" && rm "$output_path"
                else
                    __daq_api_gh_error "unzip not found, keeping archive: $output_path"
                fi
            fi
        else
            error_count=$((error_count + 1))
        fi
    done
    
    # Summary
    if [[ $download_count -gt 0 ]]; then
        echo "Downloaded $download_count artifact(s) to $output_dir"
    fi
    
    if [[ $error_count -gt 0 ]]; then
        __daq_api_gh_error "Failed to download $error_count artifact(s)"
        return 1
    fi
    
    return 0
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
                # Добавить в парсер:
            --download-artifact)
                action="download-artifact"
                shift
                ;;
            --list-runs)
                action="list-runs"
                shift
                ;;
            --list-artifacts)
                action="list-artifacts"
                shift
                ;;
            --run-id)
                if [[ $# -lt 2 ]]; then
                    __daq_api_gh_error "Option --run-id requires an argument"
                    return 1
                fi
                __DAQ_GH_API_RUN_ID="$2"
                shift 2
                ;;
            --extract)
                __DAQ_GH_API_EXTRACT=1
                shift
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
            if [[ -z "${__DAQ_GH_API_OUTPUT_DIR:-}" ]]; then
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
        # Добавить в case statement:
        list-runs)
            daq_api_gh_runs_list
            ;;

        list-artifacts)
            if [[ -z "$__DAQ_GH_API_RUN_ID" ]]; then
                __daq_api_gh_error "--run-id is required for --list-artifacts"
                return 1
            fi
            daq_api_gh_artifacts_list "$__DAQ_GH_API_RUN_ID"
            ;;

        download-artifact)
            if [[ -z "$__DAQ_GH_API_RUN_ID" ]]; then
                __daq_api_gh_error "--run-id is required for --download-artifact"
                return 1
            fi
            if [[ -z "${__DAQ_GH_API_OUTPUT_DIR:-}" ]]; then
                __daq_api_gh_error "--output-dir is required for --download-artifact"
                return 1
            fi
            daq_api_gh_artifacts_download "$__DAQ_GH_API_RUN_ID" "$__DAQ_GH_API_OUTPUT_DIR" "$__DAQ_GH_API_PATTERN" "$__DAQ_GH_API_EXTRACT"
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
