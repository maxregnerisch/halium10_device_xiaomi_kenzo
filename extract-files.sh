#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

# Required!
export DEVICE=kenzo
export VENDOR=xiaomi

export DEVICE_BRINGUP_YEAR=2016

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

LINEAGE_ROOT="$MY_DIR"/../../..

HELPER="$LINEAGE_ROOT"/vendor/lineage/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Initialize the helper for common device
setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT" true "$CLEAN_VENDOR"

extract "$MY_DIR"/proprietary-files.txt "$SRC" "$SECTION"

if [ -s "$MY_DIR"/../$DEVICE/proprietary-files.txt ]; then
    # Reinitialize the helper for device
    setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT" false "$CLEAN_VENDOR"

    extract "$MY_DIR"/../$DEVICE/proprietary-files.txt "$SRC" "$SECTION"
fi

COMMON_BLOB_ROOT="$LINEAGE_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary
patchelf --replace-needed android.frameworks.sensorservice@1.0.so android.frameworks.sensorservice@1.0-v27.so $COMMON_BLOB_ROOT/vendor/bin/slim_daemon
patchelf --replace-needed android.hardware.gnss@1.0.so android.hardware.gnss@1.0-v27.so $COMMON_BLOB_ROOT/lib64/vendor.qti.gnss@1.0.so
patchelf --replace-needed android.hardware.gnss@1.0.so android.hardware.gnss@1.0-v27.so $COMMON_BLOB_ROOT/vendor/lib64/vendor.qti.gnss@1.0_vendor.so
patchelf --replace-needed libbase.so libbase-v28.so $COMMON_BLOB_ROOT/vendor/lib64/hw/android.hardware.bluetooth@1.0-impl-qti.so
patchelf --replace-needed "libbase.so" "libbase-hax.so" $COMMON_BLOB_ROOT/vendor/lib/lib-uceservice.so
patchelf --replace-needed "libbase.so" "libbase-hax.so" $COMMON_BLOB_ROOT/vendor/lib64/lib-uceservice.so
patchelf --replace-needed "libbase.so" "libbase-hax.so" $COMMON_BLOB_ROOT/vendor/bin/imsrcsd

"$MY_DIR"/setup-makefiles.sh
./../../$VENDOR/$DEVICE/extract-files.sh $@
