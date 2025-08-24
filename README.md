# EnergyCoach

An intelligent Energy Coach agent that optimizes home energy usage by scheduling appliances based on solar forecasts, battery state, ESB usage patterns, and tariff windows.

## 🚀 Quick Start for Developers

### Prerequisites

- **Node.js 18+** and **pnpm**
- **Docker** and **Docker Compose**
- **Existing Home Assistant** instance (see [Home Assistant Setup](#home-assistant))
- **ESB Integration** already configured (see [ESB Setup](#esb))

### 1. Clone and Install

```bash
git clone <repository-url>
cd energycoach
pnpm install
```

### 2. Environment Setup

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```bash
# Home Assistant (you already have this running)
HA_BASE_URL=http://your-ha-instance:8123
HA_TOKEN=your_long_lived_token

# Energy Tariff Configuration
TARIFF_JSON={"windows":[{"name":"night","from":"00:00","to":"08:00","price_cents":22.0},{"name":"day","from":"08:00","to":"17:00","price_cents":30.5},{"name":"peak","from":"17:00","to":"19:00","price_cents":40.0},{"name":"evening","from":"19:00","to":"24:00","price_cents":30.5}]}

# Battery Settings
BATTERY_FLOOR_PERCENT=30
QUIET_HOURS_START=21:00
QUIET_HOURS_END=07:00

# Appliance Configuration
DISHWASHER_ENTITY=switch.dishwasher_plug

# Security
GATEWAY_TOKEN=your_shared_bearer_token
```

### 3. Start Development

```bash
# Start all services with hot reload
pnpm dev

# Or start individual services
pnpm --filter @energycoach/gateway dev
pnpm --filter @energycoach/planner dev
pnpm --filter @energycoach/integrations dev
```

### 4. Test the System

```bash
# Run all tests
pnpm test

# Test specific service
pnpm --filter @energycoach/planner test

# CLI testing
pnpm --filter @energycoach/cli dev
```

## 🏗️ Project Structure

```
energycoach/
├── packages/           # Shared libraries
│   ├── contracts/     # Type definitions & API contracts
│   └── config/        # Configuration management
├── services/          # Core microservices
│   ├── gateway/       # HTTP API & intent handling
│   ├── planner/       # Energy optimization engine
│   └── integrations/  # HA, ESB, Solix adapters
├── apps/              # User interfaces
│   ├── cli/          # Command-line interface
│   └── voiceproxy/   # Voice assistant webhook
└── docs/              # Documentation
```

## 🔌 Existing Integrations

### Home Assistant
You already have Home Assistant running. The EnergyCoach will connect to it to:
- Read sensor data (battery, PV, usage)
- Control smart plugs
- Send notifications

**Required Entities** (configure these in your HA):
```yaml
# Battery & Solar (Anker Solix integration)
sensor.solix_soc          # Battery state of charge
sensor.solix_pv_power     # PV generation power
sensor.solix_grid_power   # Grid power

# Usage (ESB integration)
sensor.esb_usage_30min    # Half-hourly usage data

# Control
switch.dishwasher_plug    # Dishwasher smart plug
```

## 📊 Shared Data Directory

EnergyCoach uses a centralized data directory (`data/`) that allows integrations to communicate without tight coupling:

```
data/
├── esb/                    # ESB usage data
├── homeassistant/          # HA sensor data
├── solix/                  # Battery/solar data
└── shared/                 # Cross-service data
```

**Benefits**:
- ✅ **No tight coupling** between services
- ✅ **Easy data access** for all integrations
- ✅ **Consistent data format** across the system
- ✅ **Simple debugging** and monitoring
- ✅ **Backward compatibility** with existing setups

**Usage**:
```bash
# Check data freshness
./data/manage.sh check

# Export data for other services
./data/manage.sh export esb /tmp/esb

# See example data reader
node data/example_reader.js
```

### ESB Integration
Your ESB setup provides:
- Half-hourly electricity usage data
- Daily import tracking
- Historical usage patterns

The EnergyCoach uses this to predict base load and optimize scheduling.

**Data Location**: ESB data is automatically published to `data/esb/usage_raw.json` for easy access by other services.

### Hot Reload
- `pnpm dev` starts all services with nodemon
- File changes trigger automatic restarts
- TypeScript compilation on save

## 📊 Monitoring & Debugging

### Logs
```bash
# View service logs
pnpm --filter @energycoach/gateway logs

# Docker logs
docker compose logs -f
```

### Health Checks
```bash
# Gateway health
curl http://localhost:8080/v1/health

# Planner health
curl http://localhost:8081/health
```

### Debug Mode
```bash
# Enable debug logging
DEBUG=* pnpm dev

# CLI debug mode
pnpm energy-coach plan --debug
```



### Environment Variables
```bash
# Verify environment loading
pnpm --filter @energycoach/config test

# Check config validation
node -e "require('dotenv').config(); console.log(process.env.HA_BASE_URL)"
```

### Home Assistant Connection
```bash
# Test HA connection
curl -H "Authorization: Bearer $HA_TOKEN" \
  "$HA_BASE_URL/api/states/sensor.solix_soc"
```


## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**
3. **Make your changes**
4. **Add tests for new functionality**
5. **Submit a pull request**

## 📞 Getting Help

- **Documentation**: Check the `docs/` directory
- **Issues**: Look for existing issues or create new ones
- **Discussions**: Join project discussions
- **Code**: Review existing implementations for examples

## 🔮 Roadmap

- [ ] MQTT integration for real-time updates
- [ ] Machine learning for usage pattern optimization
- [ ] Mobile app for remote control
- [ ] Integration with more energy providers
- [ ] Advanced battery management algorithms

---

**Happy coding!** 🚀 The EnergyCoach is designed to be developer-friendly with clear separation of concerns and comprehensive testing. Start with the planner service to understand the core energy optimization logic.
