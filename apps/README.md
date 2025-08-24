# Applications

This directory contains standalone applications that provide user interfaces and entry points to the EnergyCoach system. These applications consume the services and packages to deliver specific user experiences.

## 📱 Application Overview

### CLI Application (`cli/`)

**Purpose**: Command-line interface for testing, debugging, and manual energy planning

**Features**:
- Display today's energy plan
- Simulate energy scenarios for multiple days
- Interactive planning commands
- Debug mode for development
- Export plans to various formats

**Usage Examples**:
```bash
# Show today's plan
pnpm energy-coach plan

# Simulate next 3 days
pnpm energy-coach simulate --days 3

# Check current system status
pnpm energy-coach status

# Debug mode with verbose output
pnpm energy-coach plan --debug
```

**Commands**:
- `plan` - Display current energy plan
- `simulate` - Run energy simulations
- `status` - Show system health and status
- `config` - Display current configuration
- `test` - Run test scenarios

### Voice Proxy (`voiceproxy/`)

**Purpose**: Webhook endpoint for voice assistant integration (Google Assistant, Alexa)

**Features**:
- Express/Fastify webhook server
- Intent matching and routing
- Speech response formatting
- Action execution
- Error handling and fallbacks

**Integration Points**:
- Google Assistant Actions
- Amazon Alexa Skills
- Custom voice assistants
- Webhook-based automation

**Webhook Endpoint**:
```http
POST /webhook
Content-Type: application/json

{
  "intent": "ENERGY_CHECK",
  "user": "user123",
  "slots": {}
}
```

## 🏗️ Architecture

### Application Layer

```
┌─────────────┐    ┌─────────────┐
│     CLI     │    │   Voice     │
│ Application │    │   Proxy     │
└─────────────┘    └─────────────┘
       │                   │
       ▼                   ▼
┌─────────────────────────────────┐
│         Gateway Service         │
│      (Intent Processing)        │
└─────────────────────────────────┘
```

### Data Flow

1. **User Input**: CLI command or voice intent
2. **Request Formation**: Convert to standardized intent format
3. **Service Call**: Send to Gateway service
4. **Response Processing**: Format output for user interface
5. **User Feedback**: Display results or execute actions

## 🚀 Development

### Local Development

```bash
# Start CLI in development mode
pnpm --filter @energycoach/cli dev

# Start voice proxy
pnpm --filter @energycoach/voiceproxy dev

# Run all applications
pnpm dev:apps
```

### Building Applications

```bash
# Build all applications
pnpm --filter "./apps/*" build

# Build specific application
pnpm --filter @energycoach/cli build

# Production build
pnpm --filter "./apps/*" build:prod
```

### Testing Applications

```bash
# Test all applications
pnpm --filter "./apps/*" test

# Test specific application
pnpm --filter @energycoach/cli test

# Integration tests
pnpm test:integration
```

## 📋 Adding New Applications

### 1. Create Application Structure

```bash
mkdir apps/new-app
cd apps/new-app
pnpm init
```

### 2. Configure Package.json

```json
{
  "name": "@energycoach/new-app",
  "version": "1.0.0",
  "scripts": {
    "dev": "ts-node src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest"
  },
  "dependencies": {
    "@energycoach/contracts": "workspace:*",
    "@energycoach/config": "workspace:*"
  }
}
```

### 3. Add to Workspace

Update `pnpm-workspace.yaml`:
```yaml
packages:
  - 'packages/*'
  - 'services/*'
  - 'apps/*'
```

### 4. Implement Application

```typescript
// apps/new-app/src/index.ts
import { loadConfig } from '@energycoach/config';
import { IntentRequest } from '@energycoach/contracts';

async function main() {
  const config = await loadConfig();
  // Application logic here
}

main().catch(console.error);
```

## 🔌 Service Integration

### Gateway Service Communication

All applications communicate with the EnergyCoach system through the Gateway service:

```typescript
// Example: CLI calling Gateway
const response = await fetch(`${config.gateway.url}/v1/intent`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${config.gateway.token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    intent: 'ENERGY_CHECK',
    user: 'cli-user',
    slots: {}
  })
});
```

### Configuration Access

Applications use the shared config package:

```typescript
import { loadConfig } from '@energycoach/config';

const config = await loadConfig();
// Access to all configuration including:
// - Home Assistant settings
// - Tariff information
// - Security tokens
// - Appliance configurations
```

## 🧪 Testing Strategy

### Unit Tests
- Test individual application components
- Mock service dependencies
- Test user input handling
- Validate output formatting

### Integration Tests
- Test with real Gateway service
- End-to-end workflow testing
- Error handling scenarios
- Performance testing

### User Experience Tests
- CLI command usability
- Voice response quality
- Error message clarity
- Response time expectations

## 📊 Monitoring & Logging

### Application Metrics
- Request/response times
- Error rates and types
- User interaction patterns
- Performance bottlenecks

### Logging
- Structured logging with Pino
- Request tracing across services
- Error context and stack traces
- User action logging

## 🔒 Security

### Authentication
- Bearer token validation
- User identification
- Permission checking
- Rate limiting

### Input Validation
- Intent validation with Zod
- User input sanitization
- Malicious input detection
- Safe command execution

## 🚀 Deployment

### Docker Integration
- Each app has Dockerfile
- Multi-stage builds for optimization
- Health check endpoints
- Graceful shutdown handling

### Environment Configuration
- Environment-specific configs
- Secret management
- Feature flags
- Debug mode controls

## 📚 Documentation

Each application includes:
- README with usage examples
- API documentation
- Configuration guide
- Troubleshooting tips
- Integration examples
