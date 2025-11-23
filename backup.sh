#!/bin/bash

DIR="/data"
BACKUP_PATH="/backups"
RETENTION=${RETENTION:-3}  # default retention is 3 if not set


if [ ! -d "$DIR" ] || [ -z "$(ls -A "$DIR")" ]; then
    # directory does not exist or is empty
    echo "Directory $DIR does not exist or is empty. Exiting."
    exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

BACKUP_FILE="$BACKUP_PATH/backup_$TIMESTAMP.zip"

# skip paths
if [ -n "$SKIP_ZIP_PATHS" ]; then
    # Convert string representation of array to actual array
    STR_CLEAN=${SKIP_ZIP_PATHS//[\[\]\' ]/}
    IFS=',' read -r -a arr <<< "$STR_CLEAN"

    # Build the zip exclude parameters
    EXCLUDE_PARAMS=()
    for path in "${arr[@]}"; do
        EXCLUDE_PARAMS+=("-x" "$path")
    done
else
    EXCLUDE_PARAMS=()
fi

# Compute checksum of the new backup content
TMP_DIR=$(mktemp -d)
TMP_FILE="$TMP_DIR/tmp_backup.zip"
pushd "$DIR" >/dev/null 2>&1 || exit 1
echo "Zipping with command: zip -r $TMP_FILE . ${EXCLUDE_PARAMS[*]}"
zip -r -q "$TMP_FILE" . "${EXCLUDE_PARAMS[@]}"
popd >/dev/null 2>&1
TMP_CHECKSUM=$(md5sum "$TMP_FILE" | awk '{print $1}')

# Find the latest backup
LATEST_FILE=$(ls -1t "$BACKUP_PATH"/backup_*.zip 2>/dev/null | head -n 1)

if [ -n "$LATEST_FILE" ]; then
    LATEST_CHECKSUM=$(md5sum "$LATEST_FILE" | awk '{print $1}')
    if [ "$LATEST_CHECKSUM" == "$TMP_CHECKSUM" ]; then
        echo "Content identical - skipping creation."
        rm -rf "$TMP_DIR"
        exit 0
    fi
fi

# Proceed to create backup
mv "$TMP_FILE" "$BACKUP_FILE"
rm -rf "$TMP_DIR"
echo "Backup created at $BACKUP_FILE"

# Delete old backups keeping only the latest $RETENTION backups
pushd "$BACKUP_PATH" >/dev/null 2>&1 || exit 1
OLD_BACKUPS=$(ls -1t backup_*.zip 2>/dev/null | tail -n +$((RETENTION + 1)))
if [ -n "$OLD_BACKUPS" ]; then
    echo "$OLD_BACKUPS" | xargs -r rm --
    echo "Old backups deleted"
fi
popd >/dev/null 2>&1

