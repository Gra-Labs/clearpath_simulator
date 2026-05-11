# 🚀 Master Guide: AWS RoboMaker World Suite Integration for Clearpath

This guide provides the complete sequence of operations to install, configure, and run the entire suite of **AWS RoboMaker Worlds** within the Clearpath Gazebo Sim environment.

---

## 📂 1. Workspace Structure
Ensure your workspace is organized as follows:
* `~/clearpath_ws/src/clearpath_simulator/` (Existing)
* `~/clearpath_ws/src/aws-robomaker-hospital-world/` (New)
* `~/clearpath_ws/src/aws-robomaker-small-warehouse-world/` (New)
* `~/clearpath_ws/src/aws-robomaker-bookstore-world/` (New)
* `~/clearpath_ws/src/aws-robomaker-small-house-world/` (New)
* `~/clearpath_ws/src/aws-robomaker-racetrack-world/` (New)

---

## 📥 2. Repository Setup & Dependencies
Run these commands to clone all repositories and install required dependencies:

```bash
cd ~/clearpath_ws/src
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-hospital-world.git
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-small-warehouse-world.git
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-bookstore-world.git
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-small-house-world.git
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-racetrack-world.git

# Install Python dependencies for model management
pip install docopt requests lxml
```

---

## 🛠️ 3. Model Optimization & Fixes
The original AWS assets require optimization for modern Gazebo Sim (Ignition).

### **A. Download Medical Models (Hospital only)**
The Hospital world requires a separate download step:
```bash
python3 ~/clearpath_ws/src/aws-robomaker-hospital-world/fuel_utility.py download \
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
  -d ~/clearpath_ws/src/aws-robomaker-hospital-world/fuel_models --verbose
```

### **B. Fix Common Issues (Universal)**
Run these commands to standardize URIs, fix texture paths, and remove unstable inertia blocks:

```bash
# 1. Standardize URIs
find ~/clearpath_ws/src/aws-robomaker-* -name "model.sdf" -exec sed -i 's|file://models/|model://|g' {} +

# 2. Fix Texture Paths in COLLADA files
find ~/clearpath_ws/src/aws-robomaker-* -name "*.DAE" -exec sed -i 's|../../../../photos/|../../../photos/|g' {} +

# 3. Synchronize Photo Assets (Shared between House and Hospital)
cp -n ~/clearpath_ws/src/aws-robomaker-small-house-world/photos/* ~/clearpath_ws/src/aws-robomaker-hospital-world/photos/
cp -n ~/clearpath_ws/src/aws-robomaker-hospital-world/photos/* ~/clearpath_ws/src/aws-robomaker-small-house-world/photos/
```

---

## 📄 4. Launch Configuration
Update `src/clearpath_simulator/clearpath_gz/launch/gz_sim.launch.py` to include the new resource paths so Gazebo can find the models.

**Code to insert into `generate_launch_description`:**
```python
workspace_src = os.path.join(os.getenv('HOME'), 'clearpath_ws', 'src')
aws_packages = [
    'aws-robomaker-hospital-world',
    'aws-robomaker-small-warehouse-world',
    'aws-robomaker-bookstore-world',
    'aws-robomaker-small-house-world',
    'aws-robomaker-racetrack-world'
]

for pkg in aws_packages:
    pkg_path = os.path.join(workspace_src, pkg)
    if os.path.exists(pkg_path):
        packages_paths.append(pkg_path)
        packages_paths.append(os.path.join(pkg_path, 'models'))
        if 'hospital' in pkg or 'house' in pkg:
            packages_paths.append(os.path.join(pkg_path, 'photos'))
        if 'hospital' in pkg:
            packages_paths.append(os.path.join(pkg_path, 'fuel_models'))
```

---

## 🚀 5. Build & Execute
```bash
cd ~/clearpath_ws
colcon build --symlink-install --allow-overriding clearpath_gz
source install/setup.bash
```

### **Available Worlds:**
| Command | Environment |
| :--- | :--- |
| `ros2 launch clearpath_gz simulation.launch.py world:=hospital` | Hospital |
| `ros2 launch clearpath_gz simulation.launch.py world:=small_warehouse` | Warehouse |
| `ros2 launch clearpath_gz simulation.launch.py world:=bookstore` | Bookstore |
| `ros2 launch clearpath_gz simulation.launch.py world:=small_house` | House |
| `ros2 launch clearpath_gz simulation.launch.py world:=racetrack` | Racetrack |

---

## 🗺️ 6. SLAM (Cartographer) Integration
The Clearpath robot is pre-configured to use **Cartographer 3D SLAM**. To ensure synchronization and stability (no "wiggling"), use the following settings:

### **TF Configuration (`src/clearpath_3d.lua`)**
These parameters are optimized for the Jackal's sensors to provide zero-latency and jitter-free mapping:
```lua
options = {
  map_frame = "map",
  tracking_frame = "imu_0_link", -- Direct IMU tracking for stability
  published_frame = "odom",      -- Delegation to EKF
  provide_odom_frame = false,    -- Let simulator provide odom
  -- ... other options ...
}

-- Accumulate a full 360-degree rotation (5 packets) for high stability
TRAJECTORY_BUILDER_3D.num_accumulated_range_data = 5
```

### **Running SLAM**
1. **Launch Simulation:** `ros2 launch clearpath_gz simulation.launch.py world:=hospital`
2. **Launch SLAM with RViz:** 
   ```bash
   ros2 launch src/clearpath_3d.launch.py use_sim_time:=true rviz:=true
   ```
   *Note: This will open a pre-configured RViz window optimized for mapping.*

### **Running Pure Localization**
If you already have a finished map (`.pbstream`), use this to navigate without adding to the map:
```bash
ros2 launch src/clearpath_3d_localization.launch.py load_state_filename:=/home/retia/clearpath_ws/src/hospital.pbstream
```

---

## 💾 7. Saving and Loading the Map
Once you have mapped your environment, you can save and reload it:

### **A. 2D Map (for Navigation)**
**Save:**
```bash
source install/setup.bash
ros2 run nav2_map_server map_saver_cli -f ~/clearpath_ws/src/hospital_map
```

**Load/Open to View:**
```bash
# Terminal 1: Run map server
ros2 run nav2_map_server map_server --ros-args -p yaml_filename:=/home/retia/clearpath_ws/src/hospital_map.yaml -p use_sim_time:=true
# Terminal 2: Activate the map server
ros2 run nav2_util lifecycle_bringup map_server
# Terminal 3: Open RViz and add a 'Map' display with topic '/map'
ros2 run rviz2 rviz2
```

### **B. SLAM State (Full 3D Data)**
**Save:**
```bash
source install/setup.bash
ros2 service call /write_state cartographer_ros_msgs/srv/WriteState "{filename: '/home/retia/clearpath_ws/src/hospital.pbstream', include_unfinished_submaps: true}"
```

**Load/Open:**
```bash
# Continue mapping or view the 3D data in real-time
ros2 launch src/clearpath_3d.launch.py use_sim_time:=true load_state_filename:=/home/retia/clearpath_ws/src/hospital.pbstream rviz:=true
```

---

## 📍 8. Finding Robot Location (Real-time)
Because the robot runs in a namespace (`j100_0000`), standard TF commands need remapping to work.

### **Get coordinates in the Map:**
Run this to see exactly where the robot is (X, Y, Z):
```bash
ros2 run tf2_ros tf2_echo map base_link --ros-args -r /tf:=/j100_0000/tf -r /tf_static:=/j100_0000/tf_static
```

### **Get coordinates relative to Start (Odom):**
```bash
ros2 run tf2_ros tf2_echo odom base_link --ros-args -r /tf:=/j100_0000/tf -r /tf_static:=/j100_0000/tf_static
```

---

## ⚡ 9. Automation Tools
To simplify your workflow, the following scripts are available in the workspace root:

### **SLAM Automation: Finish & Save**
Closes the trajectory and saves both the .pbstream and 2D map in one go.
```bash
./finish_and_save_map.sh my_hospital_map
```

### **Full Environment Installer**
Re-installs and optimizes all 5 AWS worlds if you move to a new machine.
```bash
./install_aws_worlds.sh
```
