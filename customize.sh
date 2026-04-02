SKIPUNZIP=0

# Create consolidated data directory
mkdir -p /data/adb/muc

# Migrate old scattered files to /data/adb/muc/
for old_new in \
    "muc_config.json:config.json" \
    "muc_token:token" \
    "muc_settings:settings" \
    "muc_api_stats:api_stats" \
    "muc_last_check:last_check" \
    "muc_update_cache:update_cache" \
    "muc_ksu_package:ksu_package"; do
    old="/data/adb/$(echo $old_new | cut -d: -f1)"
    new="/data/adb/muc/$(echo $old_new | cut -d: -f2)"
    if [ -f "$old" ] && [ ! -f "$new" ]; then
        mv "$old" "$new"
    fi
done

# Also migrate from very old module-internal location
if [ -f "/data/adb/modules/module-update-checker/config.json" ] && [ ! -f "/data/adb/muc/config.json" ]; then
    cp /data/adb/modules/module-update-checker/config.json /data/adb/muc/config.json
fi

# Fix corrupted settings file (older versions wrote literal \n instead of newlines)
if [ -f "/data/adb/muc/settings" ]; then
    if grep -q '\\n' "/data/adb/muc/settings" 2>/dev/null; then
        sed 's/\\n/\n/g' "/data/adb/muc/settings" > "/data/adb/muc/settings.tmp"
        mv "/data/adb/muc/settings.tmp" "/data/adb/muc/settings"
        ui_print "- Fixed settings file format"
    fi
fi

# Clear update cache on install (cache format changed in v6.4.4)
rm -f /data/adb/muc/update_cache

ui_print "- Data directory: /data/adb/muc/"

# Install companion cleanup hook — runs on every boot, self-deletes when module is gone
mkdir -p /data/adb/service.d
cat > /data/adb/service.d/muc_companion_cleanup.sh << 'CLEANUP'
#!/system/bin/sh
# Remove MUC companion app when module-update-checker is no longer installed or is marked for removal
MODULE_DIR="/data/adb/modules/module-update-checker"
LOG="/data/adb/muc_cleanup.log"
echo "$(date): service.d ran — uid=$(id -u) ctx=$(cat /proc/self/attr/current 2>/dev/null | tr -d '\0') module_dir=$([ -d "$MODULE_DIR" ] && echo yes || echo no) remove=$([ -f "$MODULE_DIR/remove" ] && echo yes || echo no)" >> "$LOG"
if [ ! -d "$MODULE_DIR" ] || [ -f "$MODULE_DIR/remove" ]; then
    # Wait until pm is actually responsive (more reliable than sys.boot_completed)
    echo "$(date): waiting for pm..." >> "$LOG"
    for _i in $(seq 1 40); do
        pm path android >/dev/null 2>&1 && break
        sleep 3
    done
    echo "$(date): pm ready check: $(pm path android 2>&1)" >> "$LOG"

    # Try uninstall; fall back to disable-user (hides from launcher) if uninstall fails
    result=$(pm uninstall --user 0 com.dracediax.muc 2>&1)
    echo "$(date): pm uninstall --user 0: $result" >> "$LOG"
    if ! echo "$result" | grep -qi "success"; then
        result2=$(pm disable-user --user 0 com.dracediax.muc 2>&1)
        echo "$(date): pm disable-user fallback: $result2" >> "$LOG"
    fi

    rm -f /data/adb/service.d/muc_companion_cleanup.sh
    echo "$(date): cleanup done" >> "$LOG"
else
    echo "$(date): module active — no action" >> "$LOG"
fi
CLEANUP
chmod 755 /data/adb/service.d/muc_companion_cleanup.sh
