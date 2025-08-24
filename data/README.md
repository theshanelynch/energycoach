# Data Directory

This directory contains shared data that allows different integrations and services to communicate without tight coupling.

## 📁 Structure

```
data/
├── esb/                    # ESB (Electricity Supply Board) data
│   ├── usage_raw.json     # Raw half-hourly usage data
│   └── processed/         # Processed usage patterns
├── homeassistant/         # Home Assistant related data
│   ├── sensors/           # Sensor snapshots and history
│   └── states/            # Entity state history
├── solix/                 # Anker Solix battery/solar data
│   ├── battery.json       # Current battery state
│   └── pv.json            # PV generation data
└── shared/                # Cross-service shared data
    ├── energy_plan.json   # Current energy optimization plan
    └── forecasts/         # Weather and solar forecasts
```

## 🔄 Data Flow

### ESB Integration → EnergyCoach
1. ESB script fetches usage data
2. Writes to `data/esb/usage_raw.json`
3. EnergyCoach reads from this location
4. No need to dive into Home Assistant www directory

### Home Assistant → EnergyCoach
1. HA sensors export data to `data/homeassistant/sensors/`
2. EnergyCoach reads sensor data from here
3. Clean separation of concerns

### Solix Integration → EnergyCoach
1. Solix adapter reads battery/PV data
2. Writes to `data/solix/` directory
3. EnergyCoach consumes this data for planning

## 📊 Data Formats

### ESB Usage Data
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "usage_kwh": 0.85,
  "period": "10:30-11:00"
}
```

### Battery State
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "soc_percent": 65,
  "power_w": 1200,
  "charging": true
}
```

### Energy Plan
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "dishwasher": {
    "start": "13:10",
    "reason": "Solar surplus available"
  },
  "battery": {
    "precharge": false,
    "target_percent": 45
  }
}
```

## 🔧 Configuration

Set these environment variables to use the data directory:

```bash
# Data directory paths
DATA_DIR=/path/to/energycoach/data
ESB_DATA_DIR=${DATA_DIR}/esb
HA_DATA_DIR=${DATA_DIR}/homeassistant
SOLIX_DATA_DIR=${DATA_DIR}/solix
SHARED_DATA_DIR=${DATA_DIR}/shared
```

## 🚫 What NOT to do

- ❌ Don't write directly to Home Assistant www directory
- ❌ Don't hardcode paths in scripts
- ❌ Don't create tight coupling between services
- ❌ Don't store sensitive data here (use secrets/ instead)

## ✅ Best Practices

- ✅ Use environment variables for paths
- ✅ Write data in consistent JSON format
- ✅ Include timestamps with all data
- ✅ Use descriptive file names
- ✅ Keep data files small and focused
- ✅ Implement data cleanup/rotation

## 🔍 Monitoring

Check data freshness:
```bash
# Check when data was last updated
ls -la data/esb/usage_raw.json
ls -la data/solix/battery.json

# Monitor data directory size
du -sh data/
```

## 🧹 Maintenance

- Data files are automatically cleaned up
- Old sensor data is archived
- Usage patterns are aggregated over time
- Forecast data is refreshed daily
