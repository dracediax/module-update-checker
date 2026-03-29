#!/system/bin/sh
MODDIR=${0%/*}
MUC_DIR="/data/adb/muc"
mkdir -p "$MUC_DIR"
CONFIG="$MUC_DIR/config.json"
LOGFILE="$MODDIR/service.log"
LAST_NOTIF="$MODDIR/last_notif"
UPDATE_CACHE="$MUC_DIR/update_cache"
TOKEN_FILE="$MUC_DIR/token"
SETTINGS_FILE="$MUC_DIR/settings"
API_STATS_FILE="$MUC_DIR/api_stats"
LAST_CHECK_FILE="$MUC_DIR/last_check"
KSU_PKG_FILE="$MUC_DIR/ksu_package"
# Update checks run once at boot (respecting cooldown via LAST_CHECK_FILE)
# No polling loop — WebUI "Check Now" runs checks inline via exec()

log() {
    echo "$(date '+%H:%M:%S') $1" >> "$LOGFILE"
}

# Clear old log and dedup state (fresh start each boot)
echo "=== service.sh started $(date) ===" > "$LOGFILE"
rm -f "$LAST_NOTIF"

# Wait for boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
log "boot completed"

# Copy webui early so companion app doesn't show blank screen on open
APP_DIR_EARLY="/data/data/com.dracediax.muc"
if [ -d "$APP_DIR_EARLY" ] && [ -f "$MODDIR/webroot/index.html" ]; then
    cp "$MODDIR/webroot/index.html" "$APP_DIR_EARLY/webui.html" 2>/dev/null
    chmod 644 "$APP_DIR_EARLY/webui.html" 2>/dev/null
    # Set ownership to app UID so WebView can read it
    app_uid=$(stat -c %u "$APP_DIR_EARLY" 2>/dev/null || ls -ld "$APP_DIR_EARLY" | awk '{print $3}')
    [ -n "$app_uid" ] && chown "$app_uid" "$APP_DIR_EARLY/webui.html" 2>/dev/null
    # Restore SELinux context so WebView doesn't get denied
    app_ctx=$(ls -Zd "$APP_DIR_EARLY" 2>/dev/null | grep -o 'u:[^ ]*')
    [ -n "$app_ctx" ] && chcon "$app_ctx" "$APP_DIR_EARLY/webui.html" 2>/dev/null
    log "webroot copied early to companion app (uid=$app_uid ctx=$app_ctx)"
fi

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

# Check if companion app is disabled by user
companion_enabled="on"
if [ -f "$SETTINGS_FILE" ]; then
    # Handle both proper newlines and corrupted literal \n format
    companion_setting=$(grep '^companion_app=' "$SETTINGS_FILE" | cut -d= -f2)
    if [ -z "$companion_setting" ]; then
        # Fallback: check for literal \n format (older versions bug)
        companion_setting=$(grep -o 'companion_app=[a-z]*' "$SETTINGS_FILE" | cut -d= -f2)
    fi
    [ "$companion_setting" = "off" ] && companion_enabled="off"
    log "companion setting: $companion_setting (enabled=$companion_enabled)"
fi

if [ "$companion_enabled" = "on" ] && [ -f "$MODDIR/muc-helper.apk" ]; then
    log "installing companion APK..."
    pm install -r -g "$MODDIR/muc-helper.apk" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        log "companion APK installed/updated"
    else
        log "companion APK install failed"
    fi
    pm grant com.dracediax.muc android.permission.POST_NOTIFICATIONS >/dev/null 2>&1
    am start -n com.dracediax.muc/.DummyActivity >/dev/null 2>&1
elif [ "$companion_enabled" = "off" ]; then
    # Uninstall if disabled
    pm uninstall com.dracediax.muc >/dev/null 2>&1
    log "companion APK disabled by user"
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

# Smart update scheduler — sleeps until exact target time, zero polling
# Reads check_time from settings (HH:MM, default 08:00)
# Tracks last SCHEDULED check separately (manual/boot checks don't count)
SCHEDULED_CHECK_FILE="$MUC_DIR/last_scheduled_check"

get_check_time() {
    if [ -f "$SETTINGS_FILE" ]; then
        local t=$(grep '^check_time=' "$SETTINGS_FILE" | cut -d= -f2)
        # Validate HH:MM format
        if echo "$t" | grep -qE '^[0-2][0-9]:[0-5][0-9]$'; then
            echo "$t"
            return
        fi
    fi
    echo "08:00"
}

# Calculate seconds until next occurrence of HH:MM
secs_until() {
    local target_h=$(echo "$1" | cut -d: -f1 | sed 's/^0//')
    local target_m=$(echo "$1" | cut -d: -f2 | sed 's/^0//')
    local cur_h=$(date +%H | sed 's/^0//')
    local cur_m=$(date +%M | sed 's/^0//')
    local cur_s=$(date +%S | sed 's/^0//')
    local target_secs=$(( (target_h * 3600) + (target_m * 60) ))
    local cur_secs=$(( (cur_h * 3600) + (cur_m * 60) + cur_s ))
    local wait=$((target_secs - cur_secs))
    [ "$wait" -le 0 ] && wait=$((wait + 86400))
    echo "$wait"
}

schedule_checks() {
    local mode=$(get_boot_mode)
    # Migrate old values
    [ "$mode" = "always" ] && mode="every_boot"
    [ "$mode" = "daily" ] && mode="scheduled"
    [ "$mode" = "every_boot_cooldown" ] && mode="scheduled"
    [ "$mode" = "once_a_day" ] && mode="scheduled"
    log "check mode: $mode"

    if [ "$mode" = "manual" ]; then
        log "manual mode — no auto-checks"
        return
    fi

    if [ "$mode" = "every_boot" ]; then
        log "every_boot — checking now"
        check_updates
        return
    fi

    # scheduled mode: check at user-specified time daily
    local check_time=$(get_check_time)
    local now=$(date +%s)
    log "scheduled mode — target time: $check_time"

    # Failsafe: did we miss the last scheduled window?
    # If last scheduled check was >24h ago, check now (phone was off during window)
    local last_sched=0
    if [ -f "$SCHEDULED_CHECK_FILE" ]; then
        last_sched=$(cat "$SCHEDULED_CHECK_FILE" 2>/dev/null)
        [ -z "$last_sched" ] && last_sched=0
    fi
    local sched_elapsed=$((now - last_sched))

    if [ "$last_sched" -eq 0 ] || [ "$sched_elapsed" -ge 93600 ]; then
        # Never checked or missed window (>26h grace = 24h + 2h buffer)
        log "missed scheduled window (last: ${sched_elapsed}s ago) — checking now"
        check_updates
        date +%s > "$SCHEDULED_CHECK_FILE"
    else
        log "last scheduled check was ${sched_elapsed}s ago"
    fi

    # Calculate exact sleep until next check_time
    local wait=$(secs_until "$check_time")
    log "sleeping ${wait}s until $check_time"

    # Sleep until target time, check, repeat daily
    while true; do
        sleep "$wait"
        log "scheduled check at $check_time"
        check_updates
        date +%s > "$SCHEDULED_CHECK_FILE"
        wait=86400
    done &
    log "scheduler PID: $! (next check in ${wait}s at $check_time)"
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

    local sent=0
    # Try companion APK if installed
    if pm path com.dracediax.muc >/dev/null 2>&1; then
        local ksu_pkg=$(cat $KSU_PKG_FILE 2>/dev/null)
        local ksu_arg=""
        [ -n "$ksu_pkg" ] && ksu_arg="--es ksu_package $ksu_pkg"
        local result=$(am broadcast -f 0x20 -n com.dracediax.muc/.NotificationReceiver -a com.dracediax.muc.NOTIFY --es title "$title" --es text "$text" --es hint "tap" $ksu_arg 2>&1)
        log "companion app: $result"
        sent=1
    fi

    # Shell fallback if companion not installed
    if [ "$sent" = "0" ]; then
        log "companion not installed, using shell notification"
        local shell_text=$(echo "$text" | tr '\n' '|' | sed 's/|/ | /g')
        shell_text="$shell_text | Open WebUI to view"
        local result=$(su 2000 -c "/system/bin/cmd notification post -S bigtext -t 'Module Update Checker: $title' muc_updates '$shell_text'" 2>&1)
        log "shell notification: $result"
    fi

    # Save for dedup
    echo "$content" > "$LAST_NOTIF"
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
            # Write to cache: id|installed|latest|asset_url
            echo "${mod_id}|${installed}|${latest}|${asset_url}" >> "$UPDATE_CACHE"
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

# Smart update scheduler — checks now if due, then sleeps exact remaining time
schedule_checks

# Exec daemon — handles root commands from companion app
# App writes command to CMD_DIR/<id>, daemon executes and writes result to RES_DIR/<id>
# Wait for companion app data dir
APP_DIR="/data/data/com.dracediax.muc"
for i in $(seq 1 30); do
    [ -d "$APP_DIR" ] && break
    sleep 1
done

if [ -d "$APP_DIR" ]; then
    # Copy webroot to app-accessible location (app can't read /data/adb/)
    cp "$MODDIR/webroot/index.html" "$APP_DIR/webui.html" 2>/dev/null
    chmod 644 "$APP_DIR/webui.html"
    chown $(stat -c %u "$APP_DIR") "$APP_DIR/webui.html" 2>/dev/null
    log "webroot copied to $APP_DIR/webui.html"

    # Set up IPC dirs for exec daemon
    CMD_DIR="$APP_DIR/muc_cmd"
    RES_DIR="$APP_DIR/muc_res"
    mkdir -p "$CMD_DIR" "$RES_DIR"
    # Get app's SELinux context for proper file labeling
    APP_CTX=$(ls -Zd "$APP_DIR" 2>/dev/null | grep -o 'u:[^ ]*')
    chmod 777 "$CMD_DIR" "$RES_DIR" 2>/dev/null
    chcon "$APP_CTX" "$CMD_DIR" "$RES_DIR" 2>/dev/null
    log "IPC dirs ready, SELinux ctx: $APP_CTX"

    # Exec daemon — reads commands from app, executes as root, writes results
    # Runs in foreground to keep service.sh alive (needed for KSU module lifecycle)
    log "exec daemon running"
    while true; do
        for cmd_file in "$CMD_DIR"/*; do
            [ -f "$cmd_file" ] || continue
            id=$(basename "$cmd_file")
            cmd=$(cat "$cmd_file" 2>/dev/null)
            rm -f "$cmd_file"
            if [ -n "$cmd" ]; then
                result=$(sh -c "$cmd" 2>&1)
                echo "$result" > "$RES_DIR/$id"
                # Set permissions AND SELinux context so app can read
                chmod 666 "$RES_DIR/$id" 2>/dev/null
                chown $(stat -c %u "$APP_DIR") "$RES_DIR/$id" 2>/dev/null
                chcon "$APP_CTX" "$RES_DIR/$id" 2>/dev/null
            fi
        done
        sleep 0.05
    done
else
    log "companion app data dir not found — no exec daemon needed"
    # No companion app and no polling loop — service.sh exits cleanly
    # Update checks happen at boot (above) and on-demand from WebUI
    log "service.sh done"
fi
