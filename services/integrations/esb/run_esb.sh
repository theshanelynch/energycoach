#!/usr/bin/env bash
set -euo pipefail

# ESB Smart Meter Automation Script
# Downloads data and converts to Home Assistant format

# Parse command line arguments
DOWNLOAD_ONLY=false
PROCESS_ONLY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --download|-d)
            DOWNLOAD_ONLY=true
            shift
            ;;
        --process|-p)
            PROCESS_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --download, -d         Download CSV only, skip conversion"
            echo "  --process, -p          Process existing CSV only, skip download"
            echo "  --help, -h             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "🔄 Starting ESB automation workflow..."

# Check if virtual environment is activated
if [[ -z "${VIRTUAL_ENV:-}" ]]; then
    echo "⚠️  Virtual environment not activated. Activating..."
    source .venv/bin/activate
fi

# Check if .env file exists
if [[ ! -f ".env" ]]; then
    echo "❌ .env file not found. Please create it with your ESB credentials."
    exit 1
fi

# Create necessary directories
mkdir -p data/downloads data/processed

# Step 1: Download CSV data (unless process mode)
if [[ "$PROCESS_ONLY" == "true" ]]; then
    echo "⏭️  Skipping download (process mode)"
else
    echo "📥 Downloading CSV data from ESB..."
    if python esb-smart-meter-reader.py; then
        echo "✅ CSV download completed"
    else
        echo "❌ CSV download failed"
        exit 1
    fi
fi

# Step 2: Convert CSV to Home Assistant format (unless download mode)
if [[ "$DOWNLOAD_ONLY" == "true" ]]; then
    echo "⏭️  Skipping conversion (download mode)"
else
    echo "🔄 Converting CSV to Home Assistant format..."
    latest_csv=$(ls -t data/downloads/HDF_kW_*.csv 2>/dev/null | head -1)

    if [[ -n "$latest_csv" ]]; then
        echo "📁 Processing: $latest_csv"
        if python csv_to_ha_converter.py "$latest_csv"; then
            echo "✅ Conversion completed"
        else
            echo "❌ Conversion failed"
            exit 1
        fi
    else
        echo "⚠️  No CSV files found to convert"
    fi
fi

echo "🎉 ESB automation workflow completed!"
echo "📊 CSV files: data/downloads/"
echo "🏠 HA files: data/processed/"
