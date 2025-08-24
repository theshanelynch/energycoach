# ESB Smart Meter Integration

Download smart meter data from ESB Networks and convert to Home Assistant format.

## Prerequisites

- Python 3.7+
- git

## Setup

1. **Bootstrap environment:**
```bash
./bootstrap.sh
source .venv/bin/activate
```

2. **Configure credentials:**
```bash
# Edit .env file with your ESB details
ESB_METER_MPRN=your_11_digit_mprn
ESB_USER_NAME=your_email@example.com
ESB_PASSWORD=your_password
```

## Usage

**Download CSV data:**
```bash
python esb-smart-meter-reader.py
```

**Convert to Home Assistant format:**
```bash
python csv_to_ha_converter.py data/downloads/HDF_kW_*.csv
```

**Automated workflow (recommended):**
```bash
# Full workflow: download + convert
./run_esb.sh

# Download only (skip conversion)
./run_esb.sh --download

# Process only (convert existing CSV, skip download)
./run_esb.sh --process

# Show help
./run_esb.sh --help
```

## Output

- **CSV files**: `data/downloads/` (raw meter data)
- **JSON files**: `data/processed/` (Home Assistant sensor format)

## Files

- `esb-smart-meter-reader.py` - Downloads data from ESB
- `csv_to_ha_converter.py` - Converts CSV to HA format
- `.env` - Credentials (not committed)
- `requirements.txt` - Python dependencies

## Manual Download (if needed)

If the script hits rate limits or you need fresh data:

1. **Visit**: [myaccount.esbnetworks.ie](https://myaccount.esbnetworks.ie)
2. **Login** with your credentials
3. **Navigate to**: Historic Consumption → Download Data
4. **Select**: Interval kW data
5. **Download** the CSV file
6. **Place** in `data/downloads/` directory
7. **Convert** using: `python csv_to_ha_converter.py data/downloads/your_file.csv`

## Notes

- ESB portal allows max 2 logins per IP per 24 hours
- Rate limits reset at midnight
- CSV files use ESB's original naming: `HDF_kW_mprn_date.csv`