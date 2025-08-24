# Energy Coach Agent — Step by Step Build for Junior Devs

This guide takes you from zero to a working Energy Coach agent. It plans when to run the dishwasher and when to do long batch cooks using ESB usage data from Home Assistant, Anker Solix state through Home Assistant, simple weather based heuristics, and your tariff windows. It also prepares a clean voice front door through Google Assistant SDK later.

We keep everything shareable. No paid cloud is required. You can add voice later without changing the core planner.

---

## Prerequisites

You have a Home Assistant instance reachable on your network
You have a Shelly plug for the dishwasher or the dishwasher has a delayed start function
You can create a long lived access token in Home Assistant

On your dev machine install

1. Node 20 or newer
2. pnpm package manager
3. Docker and Docker Compose

Make a working folder named `energycoach` wherever you keep projects

---

## Step 1  Prepare Home Assistant sensors

Goal
Expose the data the planner needs through Home Assistant sensors so the planner can be vendor neutral and simple to share

What we need in Home Assistant

1. An ESB usage sensor that provides thirty minute import values for at least the last forty eight hours
   Name suggestion  `sensor.esb_usage_30min`
2. Solix state if available through a custom integration
   We want
   `sensor.solix_soc` as percent
   `sensor.solix_pv_power` in watts
   `sensor.solix_grid_power` in watts positive means import negative means export
   If you do not have these yet the planner will still run with mocked values
3. A Shelly entity for the dishwasher plug if you plan to auto start it
   Name suggestion  `switch.dishwasher_plug`
   If you only want reminders this can be skipped

Tasks in Home Assistant

1. Create a long lived access token
   Profile menu in the bottom left of HA UI
   Click your user then scroll to Long Lived Access Tokens and create a token. Copy it and store it safely
2. Install the ESB usage integration of your choice that exposes half hourly usage as a sensor
   If you use HACS add the custom repo for an ESB integration if needed then install it
   After install check that `sensor.esb_usage_30min` appears and has recent data
   As a fallback you can use HA History through the official API with your smart meter entity and build the same series yourself later. This guide assumes you have `sensor.esb_usage_30min`
3. Add your Anker Solix integration if supported for your model so the three sensors listed above appear. If not available skip for now
4. Add your Shelly device through Integrations and rename the switch so the entity id matches your plan. Confirm the on off service works and that its power sensor is available if the plug offers energy metering

Checkpoints

Open Developer Tools in HA then States tab. Search for each entity name above and confirm values

---

## Step 2  Create the monorepo and workspace

Goal
Create a clean TypeScript workspace with shared contracts and small services

In a terminal inside your empty `energycoach` folder run

```bash
pnpm init -y
```

Create `pnpm-workspace.yaml`

```yaml
packages:
  - packages/*
  - services/*
  - apps/*
```

Create root `package.json` scripts and workspace config

```json
{
  "name": "energycoach",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "build": "pnpm -r run build",
    "dev": "pnpm -r --parallel run dev",
    "lint": "pnpm -r run lint || true",
    "test": "pnpm -r run test || true"
  },
  "devDependencies": {
    "typescript": "^5.6.2"
  }
}
```

Create a base `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "Bundler",
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "skipLibCheck": true,
    "outDir": "dist",
    "resolveJsonModule": true
  },
  "exclude": ["node_modules", "dist"]
}
```

---

## Step 3  Shared contracts package

Goal
Define the common request and response shapes with validation so services can communicate safely

Create folder `packages/contracts`

Add `package.json`

```json
{
  "name": "@energycoach/contracts",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "dev": "tsc -w -p tsconfig.json",
    "lint": "echo skip",
    "test": "echo skip"
  },
  "dependencies": {
    "zod": "^3.23.8"
  }
}
```

Add `tsconfig.json`

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "rootDir": "src",
    "outDir": "dist"
  },
  "include": ["src"]
}
```

Add `src/index.ts`

```ts
import { z } from "zod";

export const TariffWindow = z.object({
  name: z.string(),
  from: z.string(), // HH:MM
  to: z.string(),   // HH:MM
  price_cents: z.number()
});
export type TariffWindow = z.infer<typeof TariffWindow>;

export const TariffConfig = z.object({
  windows: z.array(TariffWindow)
});
export type TariffConfig = z.infer<typeof TariffConfig>;

export const PlannerRequest = z.object({
  horizonHours: z.number().int().positive().max(72).default(48)
});
export type PlannerRequest = z.infer<typeof PlannerRequest>;

export const JobPlan = z.object({
  start: z.string().optional(), // ISO time HH:MM
  end: z.string().optional(),
  reason: z.string().optional()
});

export const PlannerResponse = z.object({
  plan: z.object({
    dishwasher: JobPlan.optional(),
    batchCook: JobPlan.optional()
  }),
  battery: z.object({
    precharge: z.boolean(),
    targetPercent: z.number().min(0).max(100).optional(),
    floorPercent: z.number().min(0).max(100)
  }),
  notes: z.string().optional(),
  costEstimateCents: z.number().optional()
});
export type PlannerResponse = z.infer<typeof PlannerResponse>;

export const IntentRequest = z.object({
  intent: z.string(),
  user: z.string().default("user"),
  slots: z.record(z.any()).default({})
});
export type IntentRequest = z.infer<typeof IntentRequest>;

export const CardItem = z.object({
  name: z.string(),
  start: z.string(),
  end: z.string().optional(),
  reason: z.string().optional()
});

export const IntentResponse = z.object({
  speech: z.string(),
  card: z
    .object({
      title: z.string(),
      items: z.array(CardItem)
    })
    .optional(),
  actions: z
    .array(
      z.discriminatedUnion("type", [
        z.object({ type: z.literal("REMINDER"), at: z.string(), message: z.string() }),
        z.object({ type: z.literal("ASK_CONSENT"), for: z.string() })
      ])
    )
    .optional()
});
export type IntentResponse = z.infer<typeof IntentResponse>;
```

Build

```bash
pnpm -w add zod
pnpm --filter @energycoach/contracts build
```

---

## Step 4  Config loader package

Goal
Centralize environment and config parsing with validation

Create folder `packages/config`

Add `package.json`

```json
{
  "name": "@energycoach/config",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "dev": "tsc -w -p tsconfig.json",
    "lint": "echo skip",
    "test": "echo skip"
  },
  "dependencies": {
    "zod": "^3.23.8",
    "dotenv": "^16.4.5"
  }
}
```

Add `tsconfig.json`

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": { "rootDir": "src", "outDir": "dist" },
  "include": ["src"]
}
```

Add `src/index.ts`

```ts
import "dotenv/config";
import { z } from "zod";
import { TariffConfig } from "@energycoach/contracts";

const EnvSchema = z.object({
  HA_BASE_URL: z.string().url(),
  HA_TOKEN: z.string().min(10),
  GATEWAY_TOKEN: z.string().min(6),
  TARIFF_JSON: z.string(),
  BATTERY_FLOOR_PERCENT: z.coerce.number().min(0).max(100).default(30),
  QUIET_HOURS_START: z.string().default("21:00"),
  QUIET_HOURS_END: z.string().default("07:00"),
  DISHWASHER_ENTITY: z.string().default("switch.dishwasher_plug"),
  SOLIX_SOC_ENTITY: z.string().default("sensor.solix_soc"),
  SOLIX_PV_ENTITY: z.string().default("sensor.solix_pv_power"),
  SOLIX_GRID_ENTITY: z.string().default("sensor.solix_grid_power"),
  ESB_USAGE_ENTITY: z.string().default("sensor.esb_usage_30min"),
  HA_NOTIFY_SERVICE: z.string().optional()
});

export type AppEnv = z.infer<typeof EnvSchema> & { tariff: TariffConfig };

export function loadConfig(): AppEnv {
  const env = EnvSchema.parse(process.env);
  const tariff = TariffConfig.parse(JSON.parse(env.TARIFF_JSON));
  return { ...env, tariff };
}
```

Build

```bash
pnpm -w add dotenv
pnpm --filter @energycoach/config build
```

---

## Step 5  Integrations package for Home Assistant and devices

Goal
Provide thin clients to talk to HA for sensors and actions

Create folder `services/integrations`

Add `package.json`

```json
{
  "name": "@energycoach/integrations",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "dev": "tsc -w -p tsconfig.json",
    "lint": "echo skip",
    "test": "echo skip"
  },
  "dependencies": {
    "node-fetch": "^3.3.2",
    "date-fns": "^3.6.0",
    "@energycoach/config": "workspace:*"
  }
}
```

Add `tsconfig.json`

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": { "rootDir": "src", "outDir": "dist" },
  "include": ["src"]
}
```

Add `src/haClient.ts`

```ts
import fetch from "node-fetch";
import { loadConfig } from "@energycoach/config";

const cfg = loadConfig();

function url(path: string) {
  return `${cfg.HA_BASE_URL}${path}`;
}

const headers = { Authorization: `Bearer ${cfg.HA_TOKEN}`, "Content-Type": "application/json" };

export async function getState(entityId: string) {
  const res = await fetch(url(`/api/states/${entityId}`), { headers });
  if (!res.ok) throw new Error(`HA state error ${res.status}`);
  return (await res.json()) as { state: string; attributes: Record<string, any> };
}

export async function callService(domain: string, service: string, data: any) {
  const res = await fetch(url(`/api/services/${domain}/${service}`), { method: "POST", headers, body: JSON.stringify(data) });
  if (!res.ok) throw new Error(`HA service error ${res.status}`);
  return await res.json();
}

export async function getHistory(entityId: string, startISO: string, endISO: string) {
  const res = await fetch(url(`/api/history/period/${encodeURIComponent(startISO)}?filter_entity_id=${entityId}&end_time=${encodeURIComponent(endISO)}`), { headers });
  if (!res.ok) throw new Error(`HA history error ${res.status}`);
  const arr = (await res.json()) as Array<Array<{ last_changed: string; state: string }>>;
  return arr[0] || [];
}
```

Add `src/esbAdapter.ts`

```ts
import { getHistory } from "./haClient.js";
import { addHours, formatISO } from "date-fns";
import { loadConfig } from "@energycoach/config";

const cfg = loadConfig();

export type UsagePoint = { ts: Date; kwh: number };

export async function getUsageSeries(hoursBack = 48): Promise<UsagePoint[]> {
  const end = new Date();
  const start = addHours(end, -hoursBack);
  const raw = await getHistory(cfg.ESB_USAGE_ENTITY, formatISO(start), formatISO(end));
  return raw
    .map(r => ({ ts: new Date(r.last_changed), kwh: Number(r.state) || 0 }))
    .filter(p => !Number.isNaN(p.kwh))
    .sort((a, b) => a.ts.getTime() - b.ts.getTime());
}

export async function getBaseLoadProfile() {
  const series = await getUsageSeries(24 * 14);
  const buckets = new Map<number, { sum: number; count: number }>();
  for (const p of series) {
    const h = p.ts.getHours();
    const b = buckets.get(h) || { sum: 0, count: 0 };
    b.sum += p.kwh;
    b.count += 1;
    buckets.set(h, b);
  }
  const hourlyKwh = Array.from({ length: 24 }, (_, h) => {
    const b = buckets.get(h) || { sum: 0.6, count: 1 };
    return b.sum / b.count;
  });
  return hourlyKwh; // average kWh per half hour would be scaled later if needed
}
```

Add `src/solixAdapter.ts`

```ts
import { getState } from "./haClient.js";
import { loadConfig } from "@energycoach/config";

const cfg = loadConfig();

export type SolixState = {
  socPercent: number;
  pvWatts: number;
  gridWatts: number; // positive means import
};

export async function getSolixState(): Promise<SolixState> {
  const soc = await getState(cfg.SOLIX_SOC_ENTITY).catch(() => ({ state: "50" } as any));
  const pv = await getState(cfg.SOLIX_PV_ENTITY).catch(() => ({ state: "800" } as any));
  const grid = await getState(cfg.SOLIX_GRID_ENTITY).catch(() => ({ state: "200" } as any));
  return {
    socPercent: Number(soc.state) || 50,
    pvWatts: Number(pv.state) || 800,
    gridWatts: Number(grid.state) || 200
  };
}
```

Add `src/shellyAdapter.ts`

```ts
import { callService, getState } from "./haClient.js";
import { loadConfig } from "@energycoach/config";

const cfg = loadConfig();

export async function powerNowWatts(): Promise<number | null> {
  try {
    const s = await getState(cfg.DISHWASHER_ENTITY.replace("switch.", "sensor.") + "_power");
    return Number(s.state);
  } catch {
    return null;
  }
}

export async function canStartDishwasher(): Promise<boolean> {
  const p = await powerNowWatts();
  if (p !== null && p > 5) return false; // looks like it is already running
  return true;
}

export async function startDishwasher() {
  await callService("switch", "turn_on", { entity_id: cfg.DISHWASHER_ENTITY });
}
```

Build

```bash
pnpm --filter @energycoach/integrations add node-fetch date-fns
pnpm --filter @energycoach/integrations build
```

---

## Step 6  Planner service

Goal
Compute a simple day plan that uses expected solar surplus or night rate and respects battery floor and quiet hours

Create folder `services/planner`

Add `package.json`

```json
{
  "name": "@energycoach/planner",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "dev": "tsc -w -p tsconfig.json",
    "lint": "echo skip",
    "test": "echo skip"
  },
  "dependencies": {
    "@energycoach/contracts": "workspace:*",
    "@energycoach/config": "workspace:*",
    "@energycoach/integrations": "workspace:*",
    "date-fns": "^3.6.0"
  }
}
```

Add `tsconfig.json`

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": { "rootDir": "src", "outDir": "dist" },
  "include": ["src"]
}
```

Add `src/index.ts`

```ts
import { PlannerResponse } from "@energycoach/contracts";
import { loadConfig } from "@energycoach/config";
import { getBaseLoadProfile } from "@energycoach/integrations/dist/esbAdapter.js";
import { getSolixState } from "@energycoach/integrations/dist/solixAdapter.js";
import { format } from "date-fns";

const cfg = loadConfig();

function inWindow(t: string, from: string, to: string) {
  const [h, m] = t.split(":").map(Number);
  const v = h * 60 + m;
  const [fh, fm] = from.split(":").map(Number);
  const [th, tm] = to.split(":").map(Number);
  const a = fh * 60 + fm;
  const b = th * 60 + tm;
  if (a <= b) return v >= a && v < b;
  return v >= a || v < b; // wraps midnight
}

function nextAt(minutes: number) {
  const d = new Date();
  d.setMinutes(minutes); d.setSeconds(0); d.setMilliseconds(0);
  return format(d, "HH:mm");
}

function pickNightStart(): string {
  const night = cfg.tariff.windows.find(w => w.name.includes("night")) || cfg.tariff.windows[0];
  const [h, m] = night.from.split(":").map(Number);
  return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
}

export async function planToday(): Promise<PlannerResponse> {
  const base = await getBaseLoadProfile();
  const solix = await getSolixState();

  // very simple PV forecast  midday shoulder bump
  const now = new Date();
  const hour = now.getHours();
  const pvKwhByHour = Array.from({ length: 24 }, (_, h) => {
    const dist = Math.max(0, 1 - Math.abs(h - 13) / 4);
    const kw = (solix.pvWatts || 800) / 1000;
    return dist * kw; // kWh per hour proxy
  });

  const floor = cfg.BATTERY_FLOOR_PERCENT;
  const quietStart = cfg.QUIET_HOURS_START;
  const quietEnd = cfg.QUIET_HOURS_END;

  const surplusByHour = pvKwhByHour.map((pv, h) => {
    const baseH = base[h] || 0.5;
    return pv - baseH;
  });

  // dishwasher plan
  let dishwasherStart: string | undefined;
  let dishwasherReason = "";

  for (let h = 10; h <= 15; h++) {
    const t = `${String(h).padStart(2, "0")}:10`;
    const okQuiet = !inWindow(t, quietStart, quietEnd);
    const okPeak = !cfg.tariff.windows.some(w => w.name.includes("peak") && inWindow(t, w.from, w.to));
    if (okQuiet && okPeak && surplusByHour[h] > 0.4) {
      dishwasherStart = t;
      dishwasherReason = "PV surplus expected";
      break;
    }
  }

  if (!dishwasherStart) {
    const t = pickNightStart();
    dishwasherStart = t;
    dishwasherReason = "night window is cheapest";
  }

  // batch cook plan  aim for midday window then backup to early evening after peak
  let cookStart: string | undefined;
  let cookEnd: string | undefined;
  let cookReason = "";

  for (let h = 11; h <= 14; h++) {
    const t = `${String(h).padStart(2, "0")}:45`;
    const okQuiet = !inWindow(t, quietStart, quietEnd);
    if (okQuiet && surplusByHour[h] > 0.6) {
      cookStart = t;
      cookEnd = `${String(h + 1).padStart(2, "0")}:15`;
      cookReason = "mostly solar coverage";
      break;
    }
  }
  if (!cookStart) {
    // after peak
    cookStart = "19:30";
    cookEnd = "21:00";
    cookReason = "avoids peak and fits evening";
  }

  const speech = `Bright midday expected. Run the dishwasher at ${dishwasherStart}. Plan a ninety minute cook starting ${cookStart}. Battery floor ${floor} percent.`;

  return {
    plan: {
      dishwasher: { start: dishwasherStart, reason: dishwasherReason },
      batchCook: { start: cookStart, end: cookEnd, reason: cookReason }
    },
    battery: { precharge: dishwasherReason.includes("night"), targetPercent: dishwasherReason.includes("night") ? 80 : undefined, floorPercent: floor },
    notes: `PV proxy uses current PV power scaled around midday. Replace with a real forecast later.`
  };
}
```

Build

```bash
pnpm --filter @energycoach/planner add date-fns
pnpm --filter @energycoach/planner build
```

---

## Step 7  Gateway service

Goal
Provide a simple HTTPS front door that Google Assistant or any client can call. It returns speech text and a small card

Create folder `services/gateway`

Add `package.json`

```json
{
  "name": "@energycoach/gateway",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "main": "dist/server.js",
  "types": "dist/server.d.ts",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "dev": "tsx watch src/server.ts",
    "lint": "echo skip",
    "test": "echo skip"
  },
  "dependencies": {
    "fastify": "^4.28.1",
    "pino": "^9.3.2",
    "@energycoach/contracts": "workspace:*",
    "@energycoach/config": "workspace:*",
    "@energycoach/planner": "workspace:*",
    "tsx": "^4.16.2"
  }
}
```

Add `tsconfig.json`

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": { "rootDir": "src", "outDir": "dist" },
  "include": ["src"]
}
```

Add `src/server.ts`

```ts
import Fastify from "fastify";
import { IntentRequest, IntentResponse } from "@energycoach/contracts";
import { loadConfig } from "@energycoach/config";
import { planToday } from "@energycoach/planner";

const cfg = loadConfig();
const app = Fastify({ logger: true });

app.addHook("preHandler", async (req, reply) => {
  const auth = req.headers["authorization"] || "";
  if (!auth.includes(cfg.GATEWAY_TOKEN)) {
    reply.code(401).send({ error: "unauthorized" });
  }
});

app.get("/v1/health", async () => ({ ok: true }));

app.post("/v1/intent", async (request, reply) => {
  const body = IntentRequest.parse(request.body);
  switch (body.intent) {
    case "ENERGY_CHECK": {
      const plan = await planToday();
      const resp: IntentResponse = {
        speech: plan.notes
          ? `Bright midday expected. ${plan.plan.dishwasher?.start ? `Run the dishwasher at ${plan.plan.dishwasher.start}.` : ""} ${plan.plan.batchCook?.start ? `Cook window ${plan.plan.batchCook.start} to ${plan.plan.batchCook.end}.` : ""} Battery floor ${plan.battery.floorPercent} percent.`
          : `Run the dishwasher at ${plan.plan.dishwasher?.start}. Cook window ${plan.plan.batchCook?.start} to ${plan.plan.batchCook?.end}.` ,
        card: {
          title: "Today plan",
          items: [
            { name: "Dishwasher", start: plan.plan.dishwasher?.start || "tbd", reason: plan.plan.dishwasher?.reason },
            { name: "Batch cook", start: plan.plan.batchCook?.start || "tbd", end: plan.plan.batchCook?.end, reason: plan.plan.batchCook?.reason }
          ]
        }
      };
      return reply.send(resp);
    }
    default:
      return reply.send({ speech: "Intent not implemented yet" });
  }
});

const port = Number(process.env.PORT || 8080);
app.listen({ port, host: "0.0.0.0" }).then(() => {
  app.log.info(`gateway on ${port}`);
});
```

Build

```bash
pnpm --filter @energycoach/gateway add fastify pino tsx
pnpm --filter @energycoach/gateway build
```

---

## Step 8  CLI app for quick checks

Goal
Let you run the planner without any voice or gateway to see the output

Create folder `apps/cli`

Add `package.json`

```json
{
  "name": "@energycoach/cli",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "bin": "dist/index.js",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "dev": "tsc -w -p tsconfig.json",
    "lint": "echo skip",
    "test": "echo skip"
  },
  "dependencies": {
    "@energycoach/planner": "workspace:*"
  }
}
```

Add `tsconfig.json`

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": { "rootDir": "src", "outDir": "dist" },
  "include": ["src"]
}
```

Add `src/index.ts`

```ts
import { planToday } from "@energycoach/planner";

const run = async () => {
  const p = await planToday();
  console.log(JSON.stringify(p, null, 2));
};
run();
```

Build

```bash
pnpm --filter @energycoach/cli build
```

Run

```bash
node apps/cli/dist/index.js
```

---

## Step 9  Voice proxy stub for later

Goal
Provide a tiny webhook that mirrors the gateway. You will connect Google Assistant or Alexa to this later. For now it forwards to the gateway and returns the same JSON

Create folder `apps/voiceproxy`

Add `package.json`

```json
{
  "name": "@energycoach/voiceproxy",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "main": "dist/server.js",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "dev": "tsx watch src/server.ts"
  },
  "dependencies": {
    "fastify": "^4.28.1",
    "node-fetch": "^3.3.2"
  }
}
```

Add `tsconfig.json`

```json
{
  "extends": "../../tsconfig.json",
  "compilerOptions": { "rootDir": "src", "outDir": "dist" },
  "include": ["src"]
}
```

Add `src/server.ts`

```ts
import Fastify from "fastify";
import fetch from "node-fetch";

const app = Fastify({ logger: true });
const GATEWAY_URL = process.env.GATEWAY_URL || "http://gateway:8080";
const GATEWAY_TOKEN = process.env.GATEWAY_TOKEN || "devtoken123";

app.post("/assistant", async (req, reply) => {
  const res = await fetch(`${GATEWAY_URL}/v1/intent`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${GATEWAY_TOKEN}` },
    body: JSON.stringify(req.body)
  });
  const json = await res.json();
  return reply.send(json);
});

const port = Number(process.env.PORT || 8082);
app.listen({ port, host: "0.0.0.0" }).then(() => app.log.info(`voiceproxy on ${port}`));
```

Build

```bash
pnpm --filter @energycoach/voiceproxy add fastify node-fetch tsx
pnpm --filter @energycoach/voiceproxy build
```

---

## Step 10  Env file and Docker Compose

Goal
Run all services together and talk to Home Assistant

Create `.env.example` in the repo root

```env
HA_BASE_URL=http://homeassistant.local:8123
HA_TOKEN=put_your_ha_long_lived_token_here
GATEWAY_TOKEN=devtoken123

TARIFF_JSON={"windows":[{"name":"night","from":"00:00","to":"08:00","price_cents":22.0},{"name":"day","from":"08:00","to":"17:00","price_cents":30.5},{"name":"peak","from":"17:00","to":"19:00","price_cents":40.0},{"name":"evening","from":"19:00","to":"24:00","price_cents":30.5}]}

BATTERY_FLOOR_PERCENT=30
QUIET_HOURS_START=21:00
QUIET_HOURS_END=07:00

DISHWASHER_ENTITY=switch.dishwasher_plug
SOLIX_SOC_ENTITY=sensor.solix_soc
SOLIX_PV_ENTITY=sensor.solix_pv_power
SOLIX_GRID_ENTITY=sensor.solix_grid_power
ESB_USAGE_ENTITY=sensor.esb_usage_30min
HA_NOTIFY_SERVICE=

GATEWAY_URL=http://gateway:8080
```

Create `Dockerfile` in the repo root for Node services

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN corepack enable && corepack prepare pnpm@9.7.1 --activate && pnpm i && pnpm -r run build
CMD ["node", "services/gateway/dist/server.js"]
```

Create `docker-compose.yml` in the repo root

```yaml
version: "3.9"
services:
  gateway:
    build: .
    container_name: energycoach_gateway
    environment:
      - HA_BASE_URL=${HA_BASE_URL}
      - HA_TOKEN=${HA_TOKEN}
      - GATEWAY_TOKEN=${GATEWAY_TOKEN}
      - TARIFF_JSON=${TARIFF_JSON}
      - BATTERY_FLOOR_PERCENT=${BATTERY_FLOOR_PERCENT}
      - QUIET_HOURS_START=${QUIET_HOURS_START}
      - QUIET_HOURS_END=${QUIET_HOURS_END}
      - DISHWASHER_ENTITY=${DISHWASHER_ENTITY}
      - SOLIX_SOC_ENTITY=${SOLIX_SOC_ENTITY}
      - SOLIX_PV_ENTITY=${SOLIX_PV_ENTITY}
      - SOLIX_GRID_ENTITY=${SOLIX_GRID_ENTITY}
      - ESB_USAGE_ENTITY=${ESB_USAGE_ENTITY}
    ports:
      - "8080:8080"
    command: ["node", "services/gateway/dist/server.js"]

  planner:
    build: .
    container_name: energycoach_planner
    environment:
      - HA_BASE_URL=${HA_BASE_URL}
      - HA_TOKEN=${HA_TOKEN}
      - GATEWAY_TOKEN=${GATEWAY_TOKEN}
      - TARIFF_JSON=${TARIFF_JSON}
      - BATTERY_FLOOR_PERCENT=${BATTERY_FLOOR_PERCENT}
      - QUIET_HOURS_START=${QUIET_HOURS_START}
      - QUIET_HOURS_END=${QUIET_HOURS_END}
      - DISHWASHER_ENTITY=${DISHWASHER_ENTITY}
      - SOLIX_SOC_ENTITY=${SOLIX_SOC_ENTITY}
      - SOLIX_PV_ENTITY=${SOLIX_PV_ENTITY}
      - SOLIX_GRID_ENTITY=${SOLIX_GRID_ENTITY}
      - ESB_USAGE_ENTITY=${ESB_USAGE_ENTITY}
    command: ["node", "services/planner/dist/index.js"]

  voiceproxy:
    build: .
    container_name: energycoach_voiceproxy
    environment:
      - GATEWAY_URL=${GATEWAY_URL}
      - GATEWAY_TOKEN=${GATEWAY_TOKEN}
    ports:
      - "8082:8082"
    command: ["node", "apps/voiceproxy/dist/server.js"]
```

Create `.env` by copying `.env.example` and fill in your values

Run

```bash
cp .env.example .env
docker compose up --build
```

Check the gateway health in a browser

`http://localhost:8080/v1/health`

---

## Step 11  Try the planner through the gateway

Use curl to invoke the intent route

```bash
curl -s -H "Authorization: Bearer devtoken123" -H "Content-Type: application/json" \
  -d '{"intent":"ENERGY_CHECK","user":"shane","slots":{}}' \
  http://localhost:8080/v1/intent | jq .
```

You should see speech and a card with start times and reasons
If Solix or ESB sensors are missing the planner uses safe defaults

---

## Step 12  Safety and consent for dishwasher control

We keep a human in the loop. The gateway will only ever issue a start action if a future Approve intent is implemented and if safety checks pass. For now the gateway returns advice and reminders only

If you want to add a one time approval implement two new intents in `services/gateway/src/server.ts`

Add cases for `APPROVE_DISHWASHER` and `MOVE_DISHWASHER` that set a short lived flag in memory or on disk and schedule the call to the HA service at the chosen time. Keep this simple in v1

---

## Step 13  Reflection loop for learning

Goal
Each night compare planned import versus actual import and record a short learning message that tweaks thresholds

Implementation sketch

1. Add a tiny store module that writes JSON under a `data` folder
2. At 21 00 read the last day of ESB usage series and compute cost using tariff windows
3. Compare with the planned schedule and summarize
4. Adjust one parameter for the next day for example how many minutes you allow the dishwasher start to drift toward night rate when PV is uncertain

You can run a Node cron in the planner process or an HA automation that calls a planner route. Keep it simple first

---

## Step 14  Add real solar forecast later

The current PV forecast is a midday proxy that scales from current PV power. Replace it with a proper forecast when you are ready. You can call a weather API or use a Home Assistant forecast entity then map irradiance to expected kWh. Keep the same planner interface so nothing else changes

---

## Step 15  Voice through Google Assistant SDK later

You now have a webhook in `apps/voiceproxy`. Map your Assistant intents to POST the same payload that the gateway accepts. Return the `speech` field as the spoken reply and optionally show the card items

Keep voice thin and stateless so the planner stays testable

---

## Step 16  Junior guidelines for debugging

1. Always test the CLI first so you know the planner works without voice
2. Use `curl` on the gateway before connecting anything else
3. If the plan looks wrong print the inputs. Check HA entity names and values
4. Keep `.env` in sync with your Home Assistant entity ids
5. When something fails read logs from the specific service in Docker Compose

---

## Step 17  What to try next

Add two more intents in the gateway
Approve plan
Move dishwasher to night

Add a reminder action by calling a HA notify service if you set `HA_NOTIFY_SERVICE` in env

Replace the PV proxy with a better forecast

Add a small HTML dashboard that shows today plan and yesterday result

---

## Done

You now have a shareable monorepo that builds and runs with simple config and that a family can use through a small set of phrases once voice is added. The planner gives reasons and respects safety. The Home Assistant adapters keep you vendor neutral. Document your entity ids and publish a starter repo for others to follow

