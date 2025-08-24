# Services

This directory contains the core microservices that power the EnergyCoach system. Each service is designed to be lightweight, testable, and focused on a specific responsibility.

## 🏗️ Architecture Overview

The services follow a microservices pattern with clear separation of concerns:

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Gateway   │───▶│   Planner   │───▶│Integrations│
│   Service   │    │   Service   │    │   Service   │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
   HTTP API         Energy Logic        HA/ESB/Solix
   Intent Handler   Job Scheduler      Data Sources
```

## 📦 Service Details

### Gateway Service (`gateway/`)

**Purpose**: HTTP API endpoint for handling intents and returning speech responses

**Key Features**:
- Fastify HTTP server with TypeScript
- Intent handling for ENERGY_CHECK, APPROVE_DISHWASHER, etc.
- Speech response generation
- Simple bearer token authentication
- Pino logging with structured output
- Basic rate limiting

**API Endpoints**:
- `POST /v1/intent` - Handle energy-related intents
- `GET /v1/health` - Health check endpoint

**Dependencies**:
- `@energycoach/contracts` - Type definitions
- `@energycoach/planner` - Planning logic
- `@energycoach/config` - Configuration management

### Planner Service (`planner/`)

**Purpose**: Core energy optimization engine that calculates optimal schedules

**Key Features**:
- Pure functions with minimal state
- Solar surplus calculation
- Job placement algorithms
- Battery SoC simulation
- Tariff-aware scheduling
- Safety constraint enforcement

**Inputs**:
- Battery SoC, PV power, grid power from Solix
- Half-hourly usage from ESB via Home Assistant
- Tariff windows and pricing
- 72-hour weather forecast

**Outputs**:
- Daily dishwasher and batch cook schedules
- Reasoning for each decision
- Battery management guidance
- Cost estimates

**Core Modules**:
- `forecastPv` - PV generation forecasting
- `forecastBaseLoad` - Base load prediction from ESB history
- `simulateSoc` - Battery state simulation
- `placeJobs` - Job scheduling optimization

### Integrations Service (`integrations/`)

**Purpose**: Unified interface to external systems and data sources

**Components**:

#### Home Assistant Client
- REST API client for sensor data
- Long-lived token authentication
- Sensor reading helpers
- Notification posting

#### ESB Adapter
- Half-hourly usage data retrieval
- Daily import tracking
- Base load profile analysis
- Historical data access

#### Solix Adapter
- Battery state monitoring
- PV power generation
- Grid power and charge limits
- Community integration support

#### Shelly Adapter
- Smart plug control
- Power monitoring
- Dishwasher safety checks
- Start/stop capabilities

## 🔄 Data Flow

1. **Intent Received**: Gateway receives intent from voice proxy or CLI
2. **Data Collection**: Integrations service fetches current state from all sources
3. **Planning**: Planner service calculates optimal schedule
4. **Response**: Gateway formats response with speech and action cards
5. **Execution**: Actions are sent to Home Assistant for appliance control

## 🧪 Testing Strategy

Each service includes:
- Unit tests for core logic
- Integration tests with mock data
- Contract tests for API compatibility
- Fixtures for different weather scenarios

## 🚀 Development

### Local Development
```bash
# Start a specific service
pnpm --filter @energycoach/gateway dev

# Run tests for a service
pnpm --filter @energycoach/planner test

# Build a service
pnpm --filter @energycoach/integrations build
```

### Service Communication
- Services communicate via HTTP APIs
- Internal service calls use shared contracts
- No direct database dependencies
- State persisted to JSON files

### Adding New Services
1. Create service directory with standard structure
2. Add to workspace configuration
3. Include in Docker Compose
4. Add environment variables
5. Implement health check endpoint

## 📊 Monitoring

Each service provides:
- Health check endpoints
- Structured logging with Pino
- Metrics for key operations
- Error tracking and reporting

## 🔒 Security

- Bearer token authentication for external APIs
- Environment variable configuration
- No hardcoded secrets
- Input validation with Zod schemas
