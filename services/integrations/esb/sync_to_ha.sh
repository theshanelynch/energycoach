#!/bin/bash

# Sync ESB processed data to Home Assistant
# This script converts the latest CSV and copies it to HA

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HA_WWW_DIR="$SCRIPT_DIR/../homeassistant/docker/www"

echo "🔄 Syncing ESB data to Home Assistant..."

# Check if we have a CSV file to process
CSV_FILES=($(ls -t sample_data/*.csv 2>/dev/null | head -1))

if [ ${#CSV_FILES[@]} -eq 0 ]; then
    echo "❌ No CSV files found in sample_data/"
    exit 1
fi

LATEST_CSV="${CSV_FILES[0]}"
echo "📊 Processing latest CSV: $LATEST_CSV"

# Convert CSV to HA format
echo "🔄 Converting CSV to Home Assistant format..."
python3 csv_to_ha_converter.py "$LATEST_CSV" --output data/processed

# Get the generated filename
HA_FILENAME=$(basename "$LATEST_CSV" .csv)_ha.json
HA_FILEPATH="data/processed/$HA_FILENAME"

if [ ! -f "$HA_FILEPATH" ]; then
    echo "❌ Failed to generate HA file"
    exit 1
fi

# Copy to Home Assistant
echo "📁 Copying to Home Assistant..."
cp "$HA_FILEPATH" "$HA_WWW_DIR/esb_usage_ha.json"

echo "✅ Successfully synced ESB data to Home Assistant!"
echo "📊 File: $HA_WWW_DIR/esb_usage_ha.json"
echo "📏 Size: $(du -h "$HA_WWW_DIR/esb_usage_ha.json" | cut -f1)"
