# ==============================================================================
# METADATA
# ==============================================================================
# FUNCTION: cli_engine
# PURPOSE: Main CLI entrypoint for orchestrating Docker operations
#
# DEPENDENCIES:
#   - env.sh (sources all dependencies)
#   - logger.sh (log, die)
#   - global_flags.sh (parse_global_flags)
#   - require_args.sh (require_args)
#   - ops/docker/lib/*.sh (business logic functions)
# ==============================================================================

# -----------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# -----------------------------------------------------------------------------
# INPUT:
#   $@ - command-line arguments (command + options)
#   DRY_RUN, CONFIRM: global flags (set by env.sh)
#
# OUTPUT:
#   stdout: command output, logs
#
# SIDE EFFECTS:
#   - Executes Docker commands
#   - Modifies configuration files
#   - Updates status files
#
# RETURNS:
#   0 on success
#   1 on failure
# -----------------------------------------------------------------------------

# ==============================================================================
# CONFIGURATION (provided by env.sh)
# ==============================================================================
# All required env vars assumed to be set by env.sh

# ==============================================================================
# IMPLEMENTATION
# ==============================================================================

cli_engine() {
    # ---------------------------------------------------------------------------
    # INPUT
    # ---------------------------------------------------------------------------

    # --- initialize script name ---
    local script_name
    script_name="$(basename "$0")"

    # --- parse global flags ---
    parse_global_flags "$@"
    set -- "${PARSED_ARGS[@]}"

    # ---------------------------------------------------------------------------
    # VALIDATION
    # ---------------------------------------------------------------------------

    # --- ensure command is provided ---
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi

    # ---------------------------------------------------------------------------
    # HELPERS (INTERNAL)
    # ---------------------------------------------------------------------------

    # --- display usage information ---
    usage() {
        cat <<EOF
Usage:
  $script_name <command> [options]

GLOBAL FLAGS:
  --dry-run    Show what would happen; do not take action
  --yes        Skip confirmation prompts (automatically set to "y")

TARGETED COMMANDS:
  apply <service> (--full | --auto | <files...>) [--force]
  export <service> (--full | --auto | <files...>) [--force]
  set-status <service> <status>

SYSTEM COMMANDS:
  deploy
  stop
  destroy <service|--all> [--runtime] [--ops]

BATCH COMMANDS:
  init
  plan
  status
EOF
    }

    # ---------------------------------------------------------------------------
    # SETUP
    # ---------------------------------------------------------------------------

    # --- extract command ---
    local cmd="$1"
    shift

    # ---------------------------------------------------------------------------
    # CORE
    # ---------------------------------------------------------------------------

    # --- dispatch based on command ---
    case "$cmd" in
        set-status)
            require_args 2 $# "set-status" usage

            local service="$1"
            local status="$2"
            local dir="$PROJECT_OPS_ROOT/$service"

            set_status "$service" "$dir" "$status"
            return 0
            ;;

        export)
            require_args 1 $# "export" usage

            local service="$1"
            if [[ "$service" == --* ]]; then
                die "export requires <service> [flags], got: '$service'"
            fi
            shift

            local ops_service_config_dir="$PROJECT_OPS_ROOT/$service"
            local runtime_service_config_dir="$PROJECT_RUNTIME_ROOT/$service"

            local direction=$(get_drift_direction "$ops_service_config_dir" "$runtime_service_config_dir")
            guard_direction "export" "$direction" "$@"

            export_from_runtime \
                "$service" \
                "$runtime_service_config_dir" \
                "$ops_service_config_dir" \
                "$@"

            return 0
            ;;

        apply)
            require_args 1 $# "apply" usage

            local service="$1"
            if [[ "$service" == --* ]]; then
                die "apply requires <service> [flags], got: '$service'"
            fi
            shift

            local ops_service_config_dir="$PROJECT_OPS_ROOT/$service"
            local runtime_service_config_dir="$PROJECT_RUNTIME_ROOT/$service"

            local direction=$(get_drift_direction "$ops_service_config_dir" "$runtime_service_config_dir")
            guard_direction "apply" "$direction" "$@"

            apply_config \
                "$service" \
                "$ops_service_config_dir" \
                "$runtime_service_config_dir" \
                "$@"

            apply_permissions \
                "$service" \
                "$runtime_service_config_dir"

            return 0
            ;;

        # --- system commands ---
        deploy)
            deploy_containers "$@"
            return 0
            ;;

        stop)
            stop_containers "$@"
            return 0
            ;;

        destroy)
            destroy_environment "$@"
            return 0
            ;;

        # --- batch commands ---
        init|plan|status)
            for service in "${SERVICES[@]}"; do

                local ops_service_config_dir="$PROJECT_OPS_ROOT/$service"
                local runtime_service_config_dir="$PROJECT_RUNTIME_ROOT/$service"

                case "$cmd" in
                    init)
                        local flow_var="INIT_FLOW_$service"

                	# --- validate if flow exists ---
                	if ! declare -p "$flow_var" &>/dev/null; then
                    	    log_warn "$service → no INIT_FLOW defined (skip)"
                    	    continue
                	fi

                	declare -n flow_ref="$flow_var"

                	for step_def in "${flow_ref[@]}"; do
                    	    # --- parse step:param ---
                    	    if [[ "$step_def" != *:* ]]; then
                        	die "$service → invalid step definition: $step_def"
                    	    fi

                    	    local step="${step_def%%:*}"
                    	    local param="${step_def##*:}"

                    	    # --- resolve data source ---
                    	    local var_name="${param}_${service}"
                    	    if ! declare -p "$var_name" &>/dev/null; then
                        	die "$service → missing variable: $var_name"
                    	    fi

                    	    declare -n data_ref="$var_name"

                    	    # --- dispatch ---
                    	    case "$step" in
				setup)
				    setup_config \
					"$service" \
					"$ops_service_config_dir" \
					"$runtime_service_config_dir" \
					"${data_ref[@]}"
				    ;;
                        	bootstrap)
                            	    bootstrap_config \
                                        "$service" \
                                        "$ops_service_config_dir" \
                                        "$BOOTSTRAP_COMPOSE" \
                                        "${data_ref[@]}"
                                    ;;
                        	seed)
                            	    seed_config \
                                	"$service" \
                                	"$ops_service_config_dir" \
                                	"${data_ref[@]}"
                            	    ;;
                        	*)
                            	    die "$service → unknown step: $step"
                            	    ;;
                    	    esac
                	done
                	;;

                    status)
                        local s
                        s="$(get_status "$service" "$ops_service_config_dir" "$runtime_service_config_dir")"
                        log "$service → $s"
                        ;;

                    plan)
                        plan_service \
                            "$service" \
                            "$ops_service_config_dir" \
                            "$runtime_service_config_dir"
                        ;;
                esac
            done
            return 0
            ;;

        *)
            die "unknown command: $cmd"
            ;;
    esac

    # ---------------------------------------------------------------------------
    # OUTPUT / RETURN
    # ---------------------------------------------------------------------------
    return 0
}
