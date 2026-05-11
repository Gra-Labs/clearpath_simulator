#!/bin/bash

# Clearpath Simulator - AWS World Suite Installer
# This script clones and optimizes the full suite of AWS RoboMaker worlds.

set -e

WS_ROOT=$(pwd)
SRC_DIR="$WS_ROOT/src"

echo "🚀 Starting AWS World Suite Installation..."

# 1. Clone Repositories
echo "📥 Cloning repositories..."
cd "$SRC_DIR"
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-hospital-world.git || true
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-small-warehouse-world.git || true
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-bookstore-world.git || true
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-small-house-world.git || true
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-racetrack-world.git || true

# 2. Dependencies
echo "📦 Installing dependencies..."
pip install docopt requests lxml --quiet

# 3. Model Preparation
echo "🏥 Downloading Hospital models..."
python3 "$SRC_DIR/aws-robomaker-hospital-world/fuel_utility.py" download \
  -m XRayMachine -m IVStand -m BloodPressureMonitor -m BPCart -m BMWCart \
  -m CGMClassic -m StorageRack -m Chair -m InstrumentCart1 -m Scrubs \
  -m PatientWheelChair -m WhiteChipChair -m TrolleyBed -m SurgicalTrolley \
  -m PotatoChipChair -m VisitorKidSit -m FemaleVisitorSit -m AdjTable \
  -m MopCart3 -m MaleVisitorSit -m Drawer -m OfficeChairBlack -m ElderLadyPatient \
  -m ElderMalePatient -m InstrumentCart2 -m MetalCabinet -m BedTable \
  -m BedsideTable -m AnesthesiaMachine -m TrolleyBedPatient -m Shower \
  -m SurgicalTrolleyMed -m StorageRackCovered -m KitchenSink -m Toilet \
  -m VendingMachine -m ParkingTrolleyMin -m PatientFSit -m MaleVisitorOnPhone \
  -m FemaleVisitor -m MalePatientBed -m StorageRackCoverOpen -m ParkingTrolleyMax \
  -d "$SRC_DIR/aws-robomaker-hospital-world/fuel_models" --verbose > /dev/null

# 4. Global Fixes
echo "🛠️ Applying URI and Texture fixes..."
# Standardize URIs
find "$SRC_DIR"/aws-robomaker-* -name "model.sdf" -exec sed -i 's|file://models/|model://|g' {} +

# Fix Texture Paths
find "$SRC_DIR"/aws-robomaker-* -name "*.DAE" -exec sed -i 's|../../../../photos/|../../../photos/|g' {} +

# Sync Photos
cp -n "$SRC_DIR"/aws-robomaker-small-house-world/photos/* "$SRC_DIR"/aws-robomaker-hospital-world/photos/ 2>/dev/null || true
cp -n "$SRC_DIR"/aws-robomaker-hospital-world/photos/* "$SRC_DIR"/aws-robomaker-small-house-world/photos/ 2>/dev/null || true

# 5. Fix Case-Sensitivity & Inertias
echo "🧹 Cleaning model files (Case-sensitivity & Inertias)..."
python3 - <<EOF
import os, re
for pkg in ['aws-robomaker-bookstore-world', 'aws-robomaker-small-warehouse-world', 'aws-robomaker-small-house-world', 'aws-robomaker-racetrack-world']:
    models_dir = os.path.join('$SRC_DIR', pkg, 'models')
    if not os.path.exists(models_dir): continue
    for root, _, files in os.walk(models_dir):
        if 'model.sdf' in files:
            sdf_path = os.path.join(root, 'model.sdf')
            with open(sdf_path, 'r') as f: content = f.read()
            # Fix case
            uris = re.findall(r'<uri>(.*?)</uri>', content)
            new_content = content
            meshes_dir = os.path.join(root, 'meshes')
            if os.path.exists(meshes_dir):
                for uri in uris:
                    if 'meshes/' in uri:
                        mesh_filename = uri.split('meshes/')[-1]
                        for f_name in os.listdir(meshes_dir):
                            if f_name.lower() == mesh_filename.lower() and f_name != mesh_filename:
                                new_content = new_content.replace(f'meshes/{mesh_filename}', f'meshes/{f_name}')
            # Strip inertia from static
            if '<static>1</static>' in new_content or '<static>true</static>' in new_content:
                new_content = re.sub(r'<inertial>.*?</inertial>', '', new_content, flags=re.DOTALL)
            if new_content != content:
                with open(sdf_path, 'w') as f: f.write(new_content)
EOF

echo "✅ Optimization Complete."

# 6. Build
echo "🏗️ Building workspace..."
cd "$WS_ROOT"
colcon build --symlink-install --allow-overriding clearpath_gz

echo "🎉 ALL WORLDS INSTALLED AND READY!"
echo "Usage: ros2 launch clearpath_gz simulation.launch.py world:=hospital|small_warehouse|bookstore|small_house|racetrack"
