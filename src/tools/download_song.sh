#!/bin/bash
# WARN: gpt slop, downloads an 'mp3'(converts to ogg) or 'ogg' via curl and puts into $TARGET_DIR

# Exit on error, undefined variable, or pipeline failure
set -euo pipefail

usage() {
    echo "Usage: $0 folder_name link"
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

FOLDER_NAME="$1"
LINK="$2"

if ! command -v ffmpeg &>/dev/null; then
    echo "Error: ffmpeg is not installed. Please install it and try again."
    exit 1
fi

TARGET_DIR="$HOME/code/game-jam/src/maps/${FOLDER_NAME}"
mkdir -p "$TARGET_DIR"

TMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Downloading from: $LINK"
cd "$TMP_DIR"

# Ensure curl is installed
if ! command -v curl &>/dev/null; then
    echo "Error: curl is not installed."
    exit 1
fi

url_decode() {
    local encoded="$1"
    printf '%b' "${encoded//%/\\x}"
}

FILENAME_ENCODED=$(basename "$LINK")
FILENAME_DECODED=$(url_decode "$FILENAME_ENCODED")
echo "Downloading file to: $FILENAME_DECODED"
curl -L -o "$FILENAME_DECODED" "$LINK"
if [ ! -f "$FILENAME_DECODED" ]; then
    echo "Error: Failed to download file."
    exit 1
fi

FILENAME="$FILENAME_DECODED"

EXT="${FILENAME##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
BASENAME="${FILENAME%.*}"

if [ "$EXT_LOWER" = "mp3" ]; then
    echo "Converting $FILENAME to OGG..."
    ffmpeg -y -loglevel error -i "$FILENAME" "${TARGET_DIR}/${BASENAME}.ogg"
    echo "Conversion complete. Saved as ${TARGET_DIR}/${BASENAME}.ogg"

elif [ "$EXT_LOWER" = "ogg" ]; then
    echo "Copying OGG file to $TARGET_DIR..."
    cp "$FILENAME" "${TARGET_DIR}/${FILENAME}"
    echo "Saved as ${TARGET_DIR}/${FILENAME}"

else
    echo "Error: Unsupported file type '$EXT'. Only mp3 and ogg are supported."
    exit 1
fi

echo "Done."
