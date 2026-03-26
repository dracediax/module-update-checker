SKIPUNZIP=0

# Migrate config from old location if it exists
if [ -f "/data/adb/modules/module-update-checker/config.json" ] && [ ! -f "/data/adb/muc_config.json" ]; then
    cp /data/adb/modules/module-update-checker/config.json /data/adb/muc_config.json
    ui_print "- Migrated config to persistent location"
fi
