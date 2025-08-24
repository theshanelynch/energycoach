#!/usr/bin/env node

/**
 * Example script showing how to read from the shared data directory
 * This demonstrates how integrations can communicate without tight coupling
 */

const fs = require('fs');
const path = require('path');

// Data directory configuration
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname);
const ESB_DATA_DIR = path.join(DATA_DIR, 'esb');
const SOLIX_DATA_DIR = path.join(DATA_DIR, 'solix');
const SHARED_DATA_DIR = path.join(DATA_DIR, 'shared');

/**
 * Read ESB usage data
 */
function readESBUsage() {
  const usageFile = path.join(ESB_DATA_DIR, 'usage_raw.json');
  
  if (!fs.existsSync(usageFile)) {
    console.log('ESB usage data not available');
    return null;
  }
  
  try {
    const data = JSON.parse(fs.readFileSync(usageFile, 'utf8'));
    console.log('ESB Usage Data:');
    console.log(`  Last updated: ${data.timestamp}`);
    console.log(`  Total usage: ${data.metadata.total_usage_kwh} kWh`);
    console.log(`  Periods: ${data.metadata.total_periods}`);
    return data;
  } catch (error) {
    console.error('Error reading ESB data:', error.message);
    return null;
  }
}

/**
 * Read Solix battery data
 */
function readSolixBattery() {
  const batteryFile = path.join(SOLIX_DATA_DIR, 'battery.json');
  
  if (!fs.existsSync(batteryFile)) {
    console.log('Solix battery data not available');
    return null;
  }
  
  try {
    const data = JSON.parse(fs.readFileSync(batteryFile, 'utf8'));
    console.log('Solix Battery Data:');
    console.log(`  Last updated: ${data.timestamp}`);
    console.log(`  SoC: ${data.soc_percent}%`);
    console.log(`  Power: ${data.power_w}W`);
    console.log(`  Charging: ${data.charging}`);
    return data;
  } catch (error) {
    console.error('Error reading Solix data:', error.message);
    return null;
  }
}

/**
 * Read current energy plan
 */
function readEnergyPlan() {
  const planFile = path.join(SHARED_DATA_DIR, 'energy_plan.json');
  
  if (!fs.existsSync(planFile)) {
    console.log('Energy plan not available');
    return null;
  }
  
  try {
    const data = JSON.parse(fs.readFileSync(planFile, 'utf8'));
    console.log('Energy Plan:');
    console.log(`  Last updated: ${data.timestamp}`);
    
    if (data.dishwasher) {
      console.log(`  Dishwasher: ${data.dishwasher.start} (${data.dishwasher.reason})`);
    }
    
    if (data.battery) {
      console.log(`  Battery: ${data.battery.precharge ? 'Pre-charge' : 'No pre-charge'}, Target: ${data.battery.target_percent}%`);
    }
    
    return data;
  } catch (error) {
    console.error('Error reading energy plan:', error.message);
    return null;
  }
}

/**
 * Main function
 */
function main() {
  console.log('EnergyCoach Data Reader Example\n');
  console.log(`Data directory: ${DATA_DIR}\n`);
  
  // Read all available data
  const esbData = readESBUsage();
  console.log();
  
  const solixData = readSolixBattery();
  console.log();
  
  const planData = readEnergyPlan();
  console.log();
  
  // Example: Use data for planning
  if (esbData && solixData) {
    console.log('Data Summary for Planning:');
    console.log(`  Current usage: ${esbData.metadata.total_usage_kwh} kWh`);
    console.log(`  Battery SoC: ${solixData.soc_percent}%`);
    console.log(`  Solar generation: ${solixData.power_w}W`);
    
    // Simple planning logic
    if (solixData.power_w > 1000 && solixData.soc_percent > 30) {
      console.log('  Recommendation: Good conditions for running high-power appliances');
    } else {
      console.log('  Recommendation: Consider waiting for better conditions');
    }
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = {
  readESBUsage,
  readSolixBattery,
  readEnergyPlan
};

