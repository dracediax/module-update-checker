#!/system/bin/sh
MODDIR=${0%/*}
CONFIG="/data/adb/muc_config.json"
TRIGGER="$MODDIR/notify_trigger"
LOGFILE="$MODDIR/service.log"
LAST_NOTIF="$MODDIR/last_notif"
UPDATE_CACHE="/data/adb/muc_update_cache"
TOKEN_FILE="/data/adb/muc_token"
SETTINGS_FILE="/data/adb/muc_settings"
API_STATS_FILE="/data/adb/muc_api_stats"
LAST_CHECK_FILE="/data/adb/muc_last_check"
CHECK_INTERVAL=86400  # 24 hours
POLL_INTERVAL=60      # check trigger file every 60s

log() {
    echo "$(date '+%H:%M:%S') $1" >> "$LOGFILE"
}

# Clear old log and dedup state (fresh start each boot)
echo "=== service.sh started $(date) ===" > "$LOGFILE"
rm -f "$LAST_NOTIF"

# Wait for boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
log "boot completed"

# Wait for network — ping GitHub up to 90s
net_wait=0
while [ "$net_wait" -lt 90 ]; do
    if ping -c 1 -W 2 github.com >/dev/null 2>&1; then
        log "network ready after ${net_wait}s"
        break
    fi
    sleep 5
    net_wait=$((net_wait + 5))
done
if [ "$net_wait" -ge 90 ]; then
    log "network timeout after 90s — proceeding anyway"
fi

# Always install/update companion APK on boot (ensures permission updates take effect)
if [ -f "$MODDIR/muc-helper.apk" ]; then
    log "installing companion APK..."
    pm install -r -g "$MODDIR/muc-helper.apk" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        log "companion APK installed/updated"
    else
        log "companion APK install failed"
    fi
    # Grant notification permission (required on Android 13+)
    pm grant com.dracediax.muc android.permission.POST_NOTIFICATIONS >/dev/null 2>&1
    # Take app out of stopped state
    am start -n com.dracediax.muc/.DummyActivity >/dev/null 2>&1
fi

track_api_call() {
    local now=$(date +%s)
    local hour_start=0
    local calls=0
    if [ -f "$API_STATS_FILE" ]; then
        local raw=$(cat "$API_STATS_FILE" 2>/dev/null)
        hour_start=$(echo "$raw" | cut -d'|' -f1)
        calls=$(echo "$raw" | cut -d'|' -f2)
    fi
    local elapsed=$((now - hour_start))
    if [ "$elapsed" -gt 3600 ]; then
        calls=0
        hour_start=$now
    fi
    calls=$((calls + 1))
    echo "${hour_start}|${calls}" > "$API_STATS_FILE"
}

get_boot_mode() {
    if [ -f "$SETTINGS_FILE" ]; then
        local mode=$(grep '^boot_check=' "$SETTINGS_FILE" | cut -d= -f2)
        [ -n "$mode" ] && echo "$mode" && return
    fi
    echo "always"
}

should_check() {
    local mode=$(get_boot_mode)
    # Migrate old values
    [ "$mode" = "always" ] && mode="every_boot_cooldown"
    [ "$mode" = "daily" ] && mode="once_a_day"
    log "boot mode: $mode"

    if [ "$mode" = "manual" ]; then
        log "skipping check — manual only mode"
        return 1
    fi

    if [ "$mode" = "once_a_day" ]; then
        if [ -f "$LAST_CHECK_FILE" ]; then
            local last=$(cat "$LAST_CHECK_FILE" 2>/dev/null)
            local now=$(date +%s)
            local elapsed=$((now - last))
            if [ "$elapsed" -lt 86400 ]; then
                log "skipping check — last check was ${elapsed}s ago (once a day mode)"
                return 1
            fi
        fi
    fi

    if [ "$mode" = "every_boot_cooldown" ]; then
        if [ -f "$LAST_CHECK_FILE" ]; then
            local last=$(cat "$LAST_CHECK_FILE" 2>/dev/null)
            local now=$(date +%s)
            local elapsed=$((now - last))
            if [ "$elapsed" -lt 3600 ]; then
                log "skipping check — last check was ${elapsed}s ago (1h cooldown)"
                return 1
            fi
        fi
    fi

    # every_boot = always check, no cooldown
    log "proceeding with check"
    return 0
}

curl_auth() {
    if [ -f "$TOKEN_FILE" ]; then
        local token=$(cat "$TOKEN_FILE" 2>/dev/null)
        if [ -n "$token" ]; then
            echo "-H 'Authorization: token $token'"
            return
        fi
    fi
    echo ""
}

send_notification() {
    local title="$1"
    local text="$2"
    local content="$title|$text"

    # Dedup: don't re-notify if same updates are still pending
    if [ -f "$LAST_NOTIF" ]; then
        local prev=$(cat "$LAST_NOTIF" 2>/dev/null)
        if [ "$prev" = "$content" ]; then
            log "notification skipped (same as last)"
            return
        fi
    fi

    log "sending notification: $title | $text"

    # Try companion APK first (explicit broadcast with ksu package for tap-to-open)
    local ksu_pkg=$(cat /data/adb/muc_ksu_package 2>/dev/null)
    local ksu_arg=""
    [ -n "$ksu_pkg" ] && ksu_arg="--es ksu_package $ksu_pkg"
    local result=$(am broadcast -f 0x20 -n com.dracediax.muc/.NotificationReceiver -a com.dracediax.muc.NOTIFY --es title "$title" --es text "$text" $ksu_arg 2>&1)
    log "companion app: $result"

    # Fallback to shell if companion not installed
    if echo "$result" | grep -qi "not found\|error"; then
        log "companion not available, falling back to shell"
        result=$(su 2000 -c "/system/bin/cmd notification post -S bigtext -t 'Module Update Checker: $title' muc_updates '$text'" 2>&1)
        log "shell notification: $result"
    fi

    # Save for dedup
    echo "$content" > "$LAST_NOTIF"
}

check_trigger() {
    if [ -f "$TRIGGER" ]; then
        local content=$(cat "$TRIGGER" 2>/dev/null)
        rm -f "$TRIGGER"
        if [ -n "$content" ]; then
            local title=$(echo "$content" | cut -d'|' -f1)
            local text=$(echo "$content" | cut -d'|' -f2-)
            send_notification "$title" "$text"
        fi
    fi
}

# Normalize version: strip v prefix, parenthetical, -release, commit hashes
normalize_version() {
    echo "$1" | sed 's/^v//i; s/ *(.*) *//g; s/-release$//i; s/[-+][0-9a-f]\{6,\}$//i' | tr -d ' ' | tr '[:upper:]' '[:lower:]'
}

# Semantic version comparison: returns 0 (true) if $2 is newer than $1
is_newer() {
    local a=$(normalize_version "$1")
    local b=$(normalize_version "$2")
    [ "$a" = "$b" ] && return 1

    # Split off pre-release
    local a_num="${a%%-*}" a_pre=""
    local b_num="${b%%-*}" b_pre=""
    [ "$a" != "$a_num" ] && a_pre="${a#*-}"
    [ "$b" != "$b_num" ] && b_pre="${b#*-}"

    # Compare numeric parts
    local IFS_OLD="$IFS"
    IFS='.'
    set -- $a_num
    local a1="${1:-0}" a2="${2:-0}" a3="${3:-0}" a4="${4:-0}"
    set -- $b_num
    local b1="${1:-0}" b2="${2:-0}" b3="${3:-0}" b4="${4:-0}"
    IFS="$IFS_OLD"

    # Compare major.minor.patch.extra
    [ "$b1" -gt "$a1" ] 2>/dev/null && return 0
    [ "$b1" -lt "$a1" ] 2>/dev/null && return 1
    [ "$b2" -gt "$a2" ] 2>/dev/null && return 0
    [ "$b2" -lt "$a2" ] 2>/dev/null && return 1
    [ "$b3" -gt "$a3" ] 2>/dev/null && return 0
    [ "$b3" -lt "$a3" ] 2>/dev/null && return 1
    [ "$b4" -gt "$a4" ] 2>/dev/null && return 0
    [ "$b4" -lt "$a4" ] 2>/dev/null && return 1

    # Numeric equal — check pre-release
    # No pre > has pre (1.0.0 > 1.0.0-rc.1)
    [ -z "$b_pre" ] && [ -n "$a_pre" ] && return 0
    [ -n "$b_pre" ] && [ -z "$a_pre" ] && return 1

    # Both have pre-release — string compare (rough but handles rc.1 < rc.2)
    [ "$b_pre" \> "$a_pre" ] && return 0
    return 1
}

check_updates() {
    log "check_updates start"

    if [ ! -f "$CONFIG" ]; then
        log "no config found"
        return
    fi

    local modules=$(cat "$CONFIG" 2>/dev/null)
    if [ -z "$modules" ]; then
        log "config empty"
        return
    fi
    log "config loaded: $(echo "$modules" | wc -c) bytes"

    local id_list="$MODDIR/tmp_ids"
    echo "$modules" | /system/bin/toybox sed -n 's/.*"id":"\([^"]*\)".*/\1/p' > "$id_list"
    local id_count=$(wc -l < "$id_list")
    log "found $id_count module IDs"

    local update_count=0
    local update_names=""

    # Clear cache before rebuilding
    > "$UPDATE_CACHE"

    while read mod_id; do
        [ -z "$mod_id" ] && continue
        log "checking: $mod_id"

        local repo=$(echo "$modules" | /system/bin/toybox sed -n "s/.*\"id\":\"${mod_id}\"[^}]*\"repo\":\"\([^\"]*\)\".*/\1/p")
        if [ -z "$repo" ]; then
            log "  no repo for $mod_id"
            continue
        fi
        log "  repo: $repo"

        local installed=""
        if [ -f "/data/adb/modules/${mod_id}/module.prop" ]; then
            installed=$(grep '^version=' "/data/adb/modules/${mod_id}/module.prop" | cut -d= -f2)
        fi
        if [ -z "$installed" ]; then
            log "  no installed version"
            continue
        fi
        log "  installed: $installed"

        local auth_header=$(curl_auth)
        local response=$(eval curl -sf --connect-timeout 5 $auth_header "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null)
        track_api_call
        if [ -z "$response" ]; then
            log "  curl failed for $repo"
            continue
        fi
        log "  response: $(echo "$response" | wc -c) bytes"

        # Use grep -o instead of sed — handles long lines and optional spaces
        local latest=$(echo "$response" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/"tag_name": *"//;s/"//')
        if [ -z "$latest" ]; then
            log "  no tag_name in response"
            continue
        fi
        log "  latest: $latest"

        # Semantic version comparison
        if is_newer "$installed" "$latest"; then
            update_count=$((update_count + 1))
            local mod_name=$(grep '^name=' "/data/adb/modules/${mod_id}/module.prop" 2>/dev/null | cut -d= -f2)
            [ -z "$mod_name" ] && mod_name="$mod_id"
            if [ -n "$update_names" ]; then
                update_names="${update_names}
${mod_name}: ${latest}"
            else
                update_names="${mod_name}: ${latest}"
            fi

            # Extract asset URL for cache
            local asset_url=$(echo "$response" | grep -o '"browser_download_url": *"[^"]*\.zip"' | head -1 | sed 's/"browser_download_url": *"//;s/"//')
            # Write to cache: id|latest|asset_url
            echo "${mod_id}|${latest}|${asset_url}" >> "$UPDATE_CACHE"
            log "  UPDATE: $installed -> $latest"
        else
            log "  up to date"
        fi
    done < "$id_list"

    rm -f "$id_list"
    log "check complete: $update_count updates, cache written"

    # Save last check timestamp
    date +%s > "$LAST_CHECK_FILE"

    if [ "$update_count" -gt 0 ]; then
        send_notification "${update_count} module update(s) available" "$update_names"
    else
        rm -f "$LAST_NOTIF"
        rm -f "$UPDATE_CACHE"
    fi
}

# Initial auto-check (respects boot mode and cooldown)
if should_check; then
    check_updates
fi

# Exec daemon — handles root commands from companion app
# App writes command to CMD_DIR/<id>, daemon executes and writes result to RES_DIR/<id>
CMD_DIR="/data/local/tmp/muc_cmd"
RES_DIR="/data/local/tmp/muc_res"
mkdir -p "$CMD_DIR" "$RES_DIR"
chmod 777 "$CMD_DIR" "$RES_DIR"

exec_daemon() {
    log "exec daemon started"
    while true; do
        for cmd_file in "$CMD_DIR"/*; do
            [ -f "$cmd_file" ] || continue
            local id=$(basename "$cmd_file")
            local cmd=$(cat "$cmd_file" 2>/dev/null)
            rm -f "$cmd_file"
            if [ -n "$cmd" ]; then
                local result=$(eval "$cmd" 2>&1)
                echo "$result" > "$RES_DIR/$id"
                chmod 666 "$RES_DIR/$id"
            fi
        done
        sleep 0.05
    done
}

# Start exec daemon in background
exec_daemon &
log "exec daemon PID: $!"

# Main loop: poll trigger file every 60s, auto-check every 24h
last_check=$(date +%s)
log "entering main loop"
while true; do
    sleep $POLL_INTERVAL
    check_trigger

    now=$(date +%s)
    elapsed=$((now - last_check))
    if [ "$elapsed" -ge "$CHECK_INTERVAL" ]; then
        if should_check; then
            check_updates
        fi
        last_check=$now
    fi
done
