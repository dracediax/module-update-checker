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

ui_print "- Data directory: /data/adb/muc/"
ui_print "- Companion app will be installed on first boot"
