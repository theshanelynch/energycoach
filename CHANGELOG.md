# Changelog

All notable changes to the EnergyCoach project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2025-08-24

### 🚀 Added
- **ESB Smart Meter Integration**
  - Enhanced CSV to Home Assistant converter with comprehensive attribute support
  - Automated data synchronization script (`sync_to_ha.sh`)
  - Support for `meter_serial` and `read_type` attributes
  - Improved date formatting from CSV to ISO format
  - Comprehensive error handling and data validation

- **Home Assistant Integration Enhancements**
  - Updated ESB energy consumption sensor configuration
  - Added comprehensive JSON attributes: `mprn`, `meter_serial`, `read_type`, `read_date`
  - Secondary sensor implementation with optimized template logic
  - Enhanced timestamp parsing and fallback value handling

- **Data Pipeline Automation**
  - Automated CSV → JSON conversion → Home Assistant integration
  - Real-time data updates every 15 minutes
  - Centralized data directory structure
  - Shared data format between ESB and Home Assistant

- **Developer Experience**
  - Clear setup and configuration scripts
  - Comprehensive error handling and logging
  - Easy data synchronization commands
  - Sample data and documentation

### 🔧 Changed
- **CSV Converter Logic**
  - Enhanced data extraction to match target Home Assistant format
  - Improved date parsing from "23-08-2025 02:30" to "2025-08-23 02:30:00"
  - Better attribute mapping and validation

- **Sensor Configuration**
  - Updated Home Assistant sensor to use new data structure
  - Enhanced Jinja2 templates for better performance
  - Improved error handling and data validation

### 📊 Data Structure Improvements
- **Standardized ESB Data Format**
  - Consistent JSON structure across all integrations
  - Proper attribute mapping from CSV to Home Assistant
  - ISO-compliant timestamp formatting
  - Comprehensive metadata preservation

### 🏗️ Architecture
- **Integration Structure**
  - Centralized data directory (`data/`)
  - Modular integration approach
  - Clear separation of concerns
  - Automated data synchronization workflows

## [0.1.0] - 2025-08-24

### 🎯 Initial Release
- **Project Foundation**
  - Basic project structure and documentation
  - Home Assistant integration framework
  - ESB smart meter data processing
  - Energy optimization planning foundation

### 📁 Project Structure
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

### 🔌 Core Integrations
- **Home Assistant**: Base integration framework
- **ESB Smart Meters**: Irish electricity usage data
- **Energy Optimization**: Planning and scheduling engine

---

## 📝 Changelog Guidelines

### Version Format
- **Major.Minor.Patch** (e.g., 1.2.3)
- **Major**: Breaking changes
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, backward compatible

### Change Categories
- **🚀 Added**: New features
- **🔧 Changed**: Changes in existing functionality
- **⚠️ Deprecated**: Soon-to-be removed features
- **❌ Removed**: Removed features
- **🐛 Fixed**: Bug fixes
- **🔒 Security**: Security improvements

### Entry Format
```markdown
## [Version] - YYYY-MM-DD

### 🚀 Added
- New feature description

### 🔧 Changed
- Changed functionality description

### 🐛 Fixed
- Bug fix description
```

---

## 🔮 Upcoming Features

### Planned for Next Release
- [ ] **Anker Solix Integration**: Battery and solar system monitoring
- [ ] **MQTT Integration**: Real-time updates
- [ ] **Machine Learning**: Usage pattern optimization
- [ ] **Mobile App**: Remote control interface
- [ ] **Advanced Battery Management**: Smart charging algorithms

### Long-term Roadmap
- [ ] **Multi-Provider Support**: Integration with more energy providers
- [ ] **Predictive Analytics**: AI-powered energy forecasting
- [ ] **Grid Services**: Demand response and grid balancing
- [ ] **Community Features**: Shared optimization strategies

---

**Note**: This changelog tracks all significant changes to the EnergyCoach project. For detailed technical documentation, see the `docs/` directory.
