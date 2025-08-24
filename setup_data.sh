#!/usr/bin/env bash
set -euo pipefail

# EnergyCoach Data Directory Setup Script
# This script helps developers set up the shared data structure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Setting up EnergyCoach Data Directory Structure..."

# Create data directory structure
echo "📁 Creating data directories..."
mkdir -p data/{esb,homeassistant/{sensors,states},solix,shared/forecasts}

# Copy environment example
if [[ ! -f "data/.env" ]]; then
  echo "⚙️  Setting up data configuration..."
  cp data/env.example data/.env
  echo "   Created data/.env (edit this file to customize paths)"
else
  echo "   data/.env already exists"
fi

# Make management script executable
echo "🔧 Setting up management tools..."
chmod +x data/manage.sh

# Create sample data files
echo "📊 Creating sample data files..."

# Sample ESB data
cat > data/esb/usage_raw.json << 'EOF'
{
  "timestamp": "2024-01-15T10:30:00Z",
  "source": "esb_integration",
  "data": [
    {
      "period": "10:00-10:30",
      "usage_kwh": 0.85,
      "timestamp": "2024-01-15T10:00:00Z"
    }
  ],
  "metadata": {
    "mprn": "10010803683",
    "total_periods": 1,
    "total_usage_kwh": 0.85
  }
}
EOF

# Sample Solix data
cat > data/solix/battery.json << 'EOF'
{
  "timestamp": "2024-01-15T10:30:00Z",
  "source": "solix_integration",
  "soc_percent": 65,
  "power_w": 1200,
  "charging": true,
  "pv_power_w": 800,
  "grid_power_w": 400
}
EOF

# Sample energy plan
cat > data/shared/energy_plan.json << 'EOF'
{
  "timestamp": "2024-01-15T10:30:00Z",
  "source": "planner_service",
  "dishwasher": {
    "start": "13:10",
    "reason": "Solar surplus available"
  },
  "battery": {
    "precharge": false,
    "target_percent": 45
  },
  "notes": "Good solar conditions expected"
}
EOF

echo "✅ Data directory structure created successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Edit data/.env to customize paths"
echo "   2. Run ./data/manage.sh check to verify setup"
echo "   3. Test with node data/example_reader.js"
echo ""
echo "🔗 Your integrations can now read from:"
echo "   - data/esb/usage_raw.json (ESB data)"
echo "   - data/solix/battery.json (Battery state)"
echo "   - data/shared/energy_plan.json (Energy plan)"
echo ""
echo "🚀 Happy coding!"

