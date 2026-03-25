#!/system/bin/sh
MODDIR=${0%/*}
CONFIG="$MODDIR/config.json"
CACHE="$MODDIR/cache.json"
CHECK_INTERVAL=86400  # 24 hours in seconds

# Wait for boot + network
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
sleep 30  # Wait for network to stabilize

send_notification() {
    local title="$1"
    local text="$2"
    local id="$3"
    /system/bin/cmd notification post -S bigtext -t "$title" "muc_$id" "$text" >/dev/null 2>&1
}

check_updates() {
    [ ! -f "$CONFIG" ] && return

    # Parse tracked modules from config
    local modules=$(cat "$CONFIG" 2>/dev/null)
    [ -z "$modules" ] && return

    # Read each tracked module
    echo "$modules" | /system/bin/toybox sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | while read mod_id; do
        # Get repo URL for this module
        local repo=$(echo "$modules" | /system/bin/toybox sed -n "s/.*\"id\":\"${mod_id}\"[^}]*\"repo\":\"\([^\"]*\)\".*/\1/p")
        [ -z "$repo" ] && continue

        # Get installed version
        local installed=""
        if [ -f "/data/adb/modules/${mod_id}/module.prop" ]; then
            installed=$(grep '^version=' "/data/adb/modules/${mod_id}/module.prop" | cut -d= -f2)
        fi
        [ -z "$installed" ] && continue

        # Check GitHub for latest release
        local api_url="https://api.github.com/repos/${repo}/releases/latest"
        local response=$(curl -sf --connect-timeout 10 "$api_url" 2>/dev/null)
        [ -z "$response" ] && continue

        local latest=$(echo "$response" | /system/bin/toybox sed -n 's/.*"tag_name":"\([^"]*\)".*/\1/p')
        [ -z "$latest" ] && continue

        # Normalize versions for comparison (strip leading v)
        local installed_clean=$(echo "$installed" | sed 's/^v//')
        local latest_clean=$(echo "$latest" | sed 's/^v//')

        if [ "$installed_clean" != "$latest_clean" ]; then
            send_notification "Module Update Available" "${mod_id}: ${installed} → ${latest}" "$mod_id"
        fi
    done
}

# Initial check
check_updates

# Keep checking every 24 hours
while true; do
    sleep $CHECK_INTERVAL
    check_updates
done
