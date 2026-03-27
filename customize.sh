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

ui_print "- Data directory: /data/adb/muc/"
