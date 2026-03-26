SKIPUNZIP=0

# Migrate config from old location if it exists
if [ -f "/data/adb/modules/module-update-checker/config.json" ] && [ ! -f "/data/adb/muc_config.json" ]; then
    cp /data/adb/modules/module-update-checker/config.json /data/adb/muc_config.json
    ui_print "- Migrated config to persistent location"
fi

# Install companion APK for rich notifications + shortcuts
if [ -f "$MODPATH/muc-helper.apk" ]; then
    pm install -r "$MODPATH/muc-helper.apk" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        ui_print "- Companion app installed"
    else
        ui_print "- Companion app install failed (notifications will use Shell fallback)"
    fi
fi
