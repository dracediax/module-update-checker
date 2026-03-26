#!/system/bin/sh
MODDIR=${0%/*}
CONFIG="/data/adb/muc_config.json"
TRIGGER="$MODDIR/notify_trigger"
LOGFILE="$MODDIR/service.log"
LAST_NOTIF="$MODDIR/last_notif"
UPDATE_CACHE="/data/adb/muc_update_cache"
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
    local result=$(su 2000 -c "/system/bin/cmd notification post -S bigtext -t 'Module Update Checker: $title' muc_updates '$text'" 2>&1)
    log "notification result: $result"

    if [ -z "$result" ] || echo "$result" | grep -qi "error\|denied\|not found"; then
        log "su 2000 failed, trying direct"
        result=$(cmd notification post -S bigtext -t "Module Update Checker: $title" muc_updates "$text" 2>&1)
        log "direct result: $result"
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

        local response=$(curl -sf --connect-timeout 5 "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null)
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

        local installed_clean=$(echo "$installed" | sed 's/^v//')
        local latest_clean=$(echo "$latest" | sed 's/^v//')

        if [ "$installed_clean" != "$latest_clean" ]; then
            update_count=$((update_count + 1))
            local mod_name=$(grep '^name=' "/data/adb/modules/${mod_id}/module.prop" 2>/dev/null | cut -d= -f2)
            [ -z "$mod_name" ] && mod_name="$mod_id"
            if [ -n "$update_names" ]; then
                update_names="${update_names}, ${mod_name}: ${latest}"
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

    if [ "$update_count" -gt 0 ]; then
        send_notification "${update_count} module update(s) available" "$update_names"
    else
        rm -f "$LAST_NOTIF"
        rm -f "$UPDATE_CACHE"
    fi
}

# Initial auto-check
check_updates

# Main loop: poll trigger file every 60s, auto-check every 24h
last_check=$(date +%s)
log "entering main loop"
while true; do
    sleep $POLL_INTERVAL
    check_trigger

    now=$(date +%s)
    elapsed=$((now - last_check))
    if [ "$elapsed" -ge "$CHECK_INTERVAL" ]; then
        check_updates
        last_check=$now
    fi
done
