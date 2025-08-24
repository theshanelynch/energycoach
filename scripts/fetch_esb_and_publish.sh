#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${ROOT}/docker/homeassistant"
WWW="${APP}/www"
SECRETS="${ROOT}/secrets/esb.env"
OUT="${APP}/www/esb_usage_30min.json"

source "${SECRETS}"

# run your vendor fetch here and capture JSON in RAW_JSON
RAW_JSON=$(python3 "${ROOT}/scripts/vendor/esb_smart_reader.py")

python3 - "${OUT}" <<'PY' "${RAW_JSON}"
import json, sys
from datetime import datetime, timedelta, timezone

out_path = sys.argv[1]
data = json.loads(sys.argv[2])

def parse_ts(s):
    from datetime import datetime
    for fmt in ("%Y-%m-%d %H:%M","%d/%m/%Y %H:%M","%Y-%m-%dT%H:%M:%S%z","%Y-%m-%dT%H:%M:%S"):
        try:
            dt = datetime.strptime(s, fmt)
            return dt
        except ValueError:
            pass
    return None

now = datetime.now(timezone.utc)
cutoff = now - timedelta(hours=48)

rows = data if isinstance(data, list) else data.get("rows", [])
series = []
for r in rows:
    ts_raw = r.get("Start") or r.get("start") or r.get("Read Date and End Time") or r.get("timestamp")
    ts = parse_ts(str(ts_raw))
    val_raw = r.get("kWh") or r.get("value") or r.get("Read Value")
    kind = str(r.get("Read Type") or r.get("type") or "").lower()
    if ts is None or val_raw is None or "import" not in kind:
        continue
    try:
        v = float(str(val_raw).replace(",", "."))
    except Exception:
        continue
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    ts = ts.astimezone(timezone.utc)
    if ts >= cutoff:
        series.append((ts, v))

series.sort()
pts = [[ts.isoformat().replace("+00:00","Z"), round(v, 6)] for ts, v in series]
if not pts:
    raise SystemExit("No recent import data")

payload = {
    "source": "esb_portal",
    "granularity": "30min",
    "unit": "kWh",
    "latest": {"timestamp": pts[-1][0], "value": pts[-1][1]},
    "last_48h": pts,
}

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False)
print(f"Wrote {out_path}")
PY
