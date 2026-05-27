apply_permissions() {
    local service="$1"
    local runtime_service_config_dir="$2"

    # --- alias ---
    local target_dir="$runtime_service_config_dir"

    local fn="PERMISSIONS_$service"

    if declare -f "$fn" >/dev/null; then
        log "$service → applying permissions"
        "$fn" "$target_dir"
        log_ok "$service → permissions applied"
    else
        log_debug "$service → no permissions defined"
    fi
}
