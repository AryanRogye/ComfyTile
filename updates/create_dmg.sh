#!/bin/bash

set -e

APP="ComfyTile.app"
APPCAST="appcast.xml"
DMG="ComfyTile-Installer.dmg"
BUILD_TEMP="BUILD-TEMP"


if ! [ -d "$APP" ]; then
    echo "$APP Not Found"
    exit 1
fi

if [ -f "$DMG" ]; then
    rm -rf $DMG
fi

cleanup() {
    # 1. capture current folder name correctly
    current_dir=$(basename "$(pwd)")

    # 2. If we are inside the temp folder, get out
    if [ "$current_dir" == "$BUILD_TEMP" ]; then
        cd ..
    fi
    
    # 3. If the temp folder exists, delete it
    if [ -d "$BUILD_TEMP" ]; then
        echo "Cleaning up temp files..."
        rm -rf "$BUILD_TEMP"
    fi
}
trap cleanup EXIT

mkdir -p $BUILD_TEMP
cp -r $APP $BUILD_TEMP

cd $BUILD_TEMP

create-dmg \
    --volname "ComfyTile Installer" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --icon "$APP" 200 190 \
    --hide-extension "$APP" \
    --app-drop-link 600 185 \
    "$DMG" \
    "./"

CWD=$(pwd)
/Users/aryanrogye/Library/Developer/Xcode/DerivedData/ComfyTile-fxrwgifdyproandpvzonpjfszjnm/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast $CWD

mv "$APPCAST" ../
mv "$DMG" ../
cd ..

echo "Built Successfuly"
