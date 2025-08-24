#!/usr/bin/env python3

"""
CSV to Home Assistant Converter
Converts ESB smart meter CSV data to Home Assistant sensor format
"""

import csv
import json
import os
from datetime import datetime
from pathlib import Path

def convert_csv_to_ha(csv_filepath, output_dir="data/processed"):
    """Convert ESB CSV data to Home Assistant sensor format"""
    
    # Create output directory
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    try:
        # Read CSV data
        with open(csv_filepath, 'r', encoding='utf-8') as f:
            csv_reader = csv.DictReader(f)
            rows = list(csv_reader)
        
        if not rows:
            print("❌ CSV file is empty")
            return None
        
        # Convert to Home Assistant format
        ha_data = []
        for row in rows:
            try:
                timestamp_str = row.get('Read Date and End Time', '')
                consumption = float(row.get('Read Value', 0))
                
                # Convert date format from "23-08-2025 02:30" to "2025-08-23 02:30:00"
                try:
                    # Parse the date string and convert to ISO format
                    date_obj = datetime.strptime(timestamp_str, '%d-%m-%Y %H:%M')
                    iso_timestamp = date_obj.strftime('%Y-%m-%d %H:%M:%S')
                except ValueError:
                    # Fallback to original format if parsing fails
                    iso_timestamp = timestamp_str
                
                ha_entry = {
                    'entity_id': 'sensor.esb_energy_consumption',
                    'state': str(consumption),
                    'attributes': {
                        'unit_of_measurement': 'kW',
                        'friendly_name': 'ESB Energy Consumption',
                        'read_date': timestamp_str,
                        'mprn': row.get('MPRN', ''),
                        'meter_serial': row.get('Meter Serial Number', ''),
                        'read_type': row.get('Read Type', '')
                    },
                    'last_changed': iso_timestamp,
                    'last_updated': iso_timestamp
                }
                ha_data.append(ha_entry)
                
            except (ValueError, KeyError) as e:
                print(f"⚠️  Skipping invalid row: {e}")
                continue
        
        # Generate output filename
        base_filename = os.path.splitext(os.path.basename(csv_filepath))[0]
        ha_filename = f"{base_filename}_ha.json"
        ha_filepath = os.path.join(output_dir, ha_filename)
        
        # Save Home Assistant JSON
        with open(ha_filepath, 'w', encoding='utf-8') as f:
            json.dump(ha_data, f, indent=2)
        
        print(f"✅ Converted {len(ha_data)} rows to: {ha_filepath}")
        return ha_filepath
        
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return None

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Convert ESB CSV to Home Assistant format')
    parser.add_argument('csv_file', help='CSV file to convert')
    parser.add_argument('--output', '-o', default='data/processed', help='Output directory (default: data/processed)')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.csv_file):
        print(f"❌ CSV file not found: {args.csv_file}")
        return 1
    
    result = convert_csv_to_ha(args.csv_file, args.output)
    return 0 if result else 1

if __name__ == "__main__":
    exit(main())
