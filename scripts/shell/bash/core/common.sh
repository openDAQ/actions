################################################################################
# CONFIGURATION - Paths
################################################################################

OPENDAQ_ACTIONS_SCRIPTS_PATH=""
OPENDAQ_ACTIONS_SCRIPTS_CORE="${OPENDAQ_ACTIONS_SCRIPTS_DIR}/core"

################################################################################
# PUBLIC API - Initialization
################################################################################

# Initialize test framework common state
# Args: $1 - script path (path to script being tested)
#       $2 - suite name (name of test suite)
#       $3 - verbose flag (optional, "true" or "false", default: false)
#       $4 - debug flag (optional, "true" or "false", default: false)
# Sets: Global state variables
# Returns: 0 on success, 1 on error
daq_actions_core_common_init() {
    local scripts_path="$1"

        # Validate required arguments
    if [ -z "$script_path" ]; then
        echo "ERROR: Script path is required" >&2
        return 1
    fi

    OPENDAQ_ACTIONS_SCRIPTS_PATH="$scripts_path"

}
