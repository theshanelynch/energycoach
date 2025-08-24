# Packages

This directory contains shared packages that provide common functionality across the EnergyCoach monorepo. These packages are designed to be reusable, well-tested, and maintain consistent interfaces.

## 📦 Package Overview

### Core Packages

#### `contracts` - Type Definitions & API Contracts

**Purpose**: Centralized type definitions and API contracts for all services

**Contents**:
- Zod schemas for request/response validation
- TypeScript interfaces and types
- OpenAPI/Swagger specifications
- Shared constants and enums

**Key Exports**:
```typescript
// Intent handling
export interface IntentRequest {
  intent: string;
  user: string;
  slots: Record<string, any>;
}

export interface IntentResponse {
  speech: string;
  card: ActionCard;
  actions: Action[];
}

// Planning
export interface PlannerRequest {
  horizonHours?: number;
}

export interface PlannerResponse {
  plan: DailyPlan;
  battery: BatteryGuidance;
  notes: string;
  costEstimateCents?: number;
}
```

**Usage**:
```typescript
import { IntentRequest, IntentResponse } from '@energycoach/contracts';

// All services import types from here
const request: IntentRequest = { /* ... */ };
```

#### `config` - Configuration Management

**Purpose**: Centralized configuration loading and validation

**Features**:
- Environment variable loading with dotenv
- Zod-based configuration validation
- Type-safe configuration objects
- Default value management
- Configuration file support

**Configuration Schema**:
```typescript
export interface EnergyCoachConfig {
  homeAssistant: {
    baseUrl: string;
    token: string;
  };
  tariff: TariffWindows;
  battery: {
    floorPercent: number;
    quietHoursStart: string;
    quietHoursEnd: string;
  };
  appliances: {
    dishwasherEntity: string;
  };
  security: {
    gatewayToken: string;
  };
}
```

**Usage**:
```typescript
import { loadConfig } from '@energycoach/config';

const config = await loadConfig();
// Fully typed and validated configuration
```

## 🔧 Development

### Package Structure

Each package follows a standard structure:

```
packages/
├── contracts/
│   ├── src/
│   │   ├── index.ts          # Main exports
│   │   ├── intents.ts        # Intent types
│   │   ├── planning.ts       # Planning types
│   │   └── schemas.ts        # Zod schemas
│   ├── package.json
│   ├── tsconfig.json
│   └── README.md
├── config/
│   ├── src/
│   │   ├── index.ts          # Main exports
│   │   ├── schema.ts         # Configuration schema
│   │   ├── loader.ts         # Configuration loader
│   │   └── defaults.ts       # Default values
│   ├── package.json
│   ├── tsconfig.json
│   └── README.md
```

### Building Packages

```bash
# Build all packages
pnpm --filter "./packages/*" build

# Build specific package
pnpm --filter @energycoach/contracts build

# Watch mode for development
pnpm --filter @energycoach/contracts dev
```

### Testing Packages

```bash
# Test all packages
pnpm --filter "./packages/*" test

# Test specific package
pnpm --filter @energycoach/contracts test

# Test with coverage
pnpm --filter @energycoach/contracts test:coverage
```

## 📋 Adding New Packages

### 1. Create Package Structure

```bash
mkdir packages/new-package
cd packages/new-package
pnpm init
```

### 2. Configure Package.json

```json
{
  "name": "@energycoach/new-package",
  "version": "1.0.0",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "test": "jest",
    "lint": "eslint src/**/*.ts"
  },
  "dependencies": {
    "@energycoach/contracts": "workspace:*"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "jest": "^29.0.0"
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

### 4. Export from Package

```typescript
// packages/new-package/src/index.ts
export { NewFeature } from './new-feature';
export type { NewFeatureConfig } from './types';
```

## 🔗 Package Dependencies

### Dependency Graph

```
contracts (no dependencies)
    ↑
config (depends on contracts)
    ↑
services (depend on contracts + config)
    ↑
apps (depend on all packages)
```

### Version Management

- All packages use workspace dependencies (`workspace:*`)
- Version bumps are coordinated across the monorepo
- Breaking changes require updates to dependent packages
- Semantic versioning is maintained for external releases

## 📚 Documentation

Each package includes:
- README.md with usage examples
- JSDoc comments for all public APIs
- TypeScript definitions for IDE support
- Example code in the package directory

## 🧪 Testing Strategy

### Unit Tests
- Each package has comprehensive unit tests
- Tests cover all public APIs
- Mock data and fixtures included
- High test coverage requirements

### Integration Tests
- Cross-package integration testing
- Contract validation testing
- End-to-end workflow testing

### Type Safety
- Strict TypeScript configuration
- No `any` types in public APIs
- Comprehensive type coverage
- Runtime validation with Zod

## 🚀 Publishing

### Internal Usage
- Packages are consumed internally via workspace dependencies
- No external publishing required for development
- Version management through pnpm workspace

### External Publishing (Future)
- Packages can be published to npm registry
- Independent versioning for external consumers
- Documentation and examples for external users
