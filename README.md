# clearpath_simulator - ROS 2 Humble Edition

> **⚠️ This repository requires ROS 2 Humble** — A specialized fork of [clearpathrobotics/clearpath_simulator](https://github.com/clearpathrobotics/clearpath_simulator/tree/humble) with integrated AWS RoboMaker world support for Gazebo simulation.

## Overview

This is an enhanced version of the Clearpath simulator featuring:
- Full **ROS 2 Humble** compatibility
- **AWS RoboMaker Worlds** integration (Hospital, Warehouse, Bookstore, House, Racetrack)
- **Cartographer 3D SLAM** pre-configured for mapping and localization
- Ready-to-use automation scripts for map saving and environment setup

---

## Prerequisites

- **ROS 2 Humble** ([Installation Guide](https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html))
- **Ignition Fortress** (Gazebo)
- Python 3 with dependencies: `docopt`, `requests`, `lxml`
- Linux environment (Ubuntu 22.04 recommended)

---

## Quick Start

### 1. Install Ignition Fortress

```bash
sudo apt-get update && sudo apt-get install wget
sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
sudo apt-get update && sudo apt-get install ignition-fortress
```

### 2. Setup Workspace

```bash
mkdir -p ~/clearpath_ws/src
cd ~/clearpath_ws/src
git clone https://github.com/Gra-Labs/clearpath_simulator.git
cd ~/clearpath_ws
rosdep install -r --from-paths src -i -y
```

### 3. Install AWS Worlds (Optional but Recommended)

Run the automated installer to set up all AWS RoboMaker worlds:

```bash
cd ~/clearpath_ws
bash src/clearpath_simulator/install_aws_worlds.sh
```

Or manually install dependencies:

```bash
pip install docopt requests lxml
```

### 4. Build Workspace

```bash
cd ~/clearpath_ws
colcon build --symlink-install
source install/setup.bash
```

### 5. Setup Robot Configuration

```bash
mkdir -p ~/clearpath
# Copy your robot.yaml into ~/clearpath
```

---

## Basic Launch

### Standard Simulation

```bash
source ~/clearpath_ws/install/setup.bash
ros2 launch clearpath_gz simulation.launch.py
```

---

## AWS RoboMaker Worlds

This simulator includes five highly realistic AWS RoboMaker simulation worlds. Launch them with:

| Command | Environment | Description |
|---------|------------|-------------|
| `ros2 launch clearpath_gz simulation.launch.py world:=hospital` | Hospital | Medical facility with equipment and layouts |
| `ros2 launch clearpath_gz simulation.launch.py world:=small_warehouse` | Warehouse | Industrial warehouse with shelving |
| `ros2 launch clearpath_gz simulation.launch.py world:=bookstore` | Bookstore | Retail bookstore environment |
| `ros2 launch clearpath_gz simulation.launch.py world:=small_house` | House | Residential home interior |
| `ros2 launch clearpath_gz simulation.launch.py world:=racetrack` | Racetrack | Outdoor race track circuit |

### Example: Hospital World

```bash
source ~/clearpath_ws/install/setup.bash
ros2 launch clearpath_gz simulation.launch.py world:=hospital
```

---

## 🗺️ SLAM & Mapping

### Cartographer 3D SLAM

The Jackal robot is pre-configured with **Cartographer 3D SLAM** for autonomous mapping and localization.

#### Launch SLAM with RViz

```bash
# Terminal 1: Start simulation
ros2 launch clearpath_gz simulation.launch.py world:=hospital

# Terminal 2: Launch SLAM with visualization
ros2 launch src/clearpath_3d.launch.py use_sim_time:=true rviz:=true
```

This opens a pre-configured RViz window optimized for 3D mapping.

#### Pure Localization (Using Existing Map)

If you already have a finished `.pbstream` map file:

```bash
ros2 launch src/clearpath_3d_localization.launch.py use_sim_time:=true load_state_filename:=/home/retia/clearpath_ws/src/hospital.pbstream
```

---

## 💾 Saving & Loading Maps

### Save 2D Map (for Navigation)

```bash
source install/setup.bash
ros2 run nav2_map_server map_saver_cli -f ~/clearpath_ws/src/hospital_map
```

**Load & View 2D Map:**

```bash
# Terminal 1: Start map server
ros2 run nav2_map_server map_server --ros-args -p yaml_filename:=/home/retia/clearpath_ws/src/hospital_map.yaml -p use_sim_time:=true

# Terminal 2: Activate lifecycle
ros2 run nav2_util lifecycle_bringup map_server

# Terminal 3: Open RViz and add Map display with topic '/map'
ros2 run rviz2 rviz2
```

### Save SLAM State (Full 3D Data)

```bash
source install/setup.bash
ros2 service call /write_state cartographer_ros_msgs/srv/WriteState "{filename: '/home/retia/clearpath_ws/src/hospital.pbstream', include_unfinished_submaps: true}"
```

**Load SLAM State:**

```bash
ros2 launch src/clearpath_3d.launch.py use_sim_time:=true load_state_filename:=/home/retia/clearpath_ws/src/hospital.pbstream rviz:=true
```

---

## 📍 Robot Localization

The robot runs in the `j100_0000` namespace. Use these commands to query its position:

### Get Map Coordinates (Global Position)

```bash
ros2 run tf2_ros tf2_echo map base_link --ros-args -r /tf:=/j100_0000/tf -r /tf_static:=/j100_0000/tf_static
```

### Get Odometry Coordinates (Local Position)

```bash
ros2 run tf2_ros tf2_echo odom base_link --ros-args -r /tf:=/j100_0000/tf -r /tf_static:=/j100_0000/tf_static
```

---

## 🚀 Automation Scripts

### Finish & Save Map

Automatically close the trajectory and save both `.pbstream` and 2D map:

```bash
cd ~/clearpath_ws
bash src/clearpath_simulator/finish_and_save_map.sh my_hospital_map
```

### Full Environment Installer

Re-install and optimize all AWS worlds (useful when moving to a new machine):

```bash
cd ~/clearpath_ws
bash src/clearpath_simulator/install_aws_worlds.sh
```

---

## 📂 Workspace Structure

After full setup, your workspace should look like this:

```
~/clearpath_ws/
├── src/
│   ├── clearpath_simulator/              (This repo)
│   ├── aws-robomaker-hospital-world/
│   ├── aws-robomaker-small-warehouse-world/
│   ├── aws-robomaker-bookstore-world/
│   ├── aws-robomaker-small-house-world/
│   └── aws-robomaker-racetrack-world/
├── build/
├── install/
└── log/
```

---

## 🛠️ Advanced Configuration

### Launch File Configuration

To enable AWS world support, the launch files automatically detect and configure paths to all AWS RoboMaker world packages. The simulator searches for models in:

- Standard Gazebo paths
- AWS world directories (`models/`, `photos/`, `fuel_models/`)
- Clearpath simulator paths

### Custom Worlds

You can extend this setup with additional worlds by:

1. Adding world packages to `~/clearpath_ws/src/`
2. Updating `src/clearpath_simulator/clearpath_gz/launch/gz_sim.launch.py` with new package paths
3. Creating corresponding YAML world files in `src/clearpath_simulator/clearpath_gz/worlds/`

---

## Troubleshooting

**Issue:** Models not loading in Gazebo
- **Solution:** Ensure all AWS world packages are cloned and the workspace is rebuilt with `colcon build --symlink-install`

**Issue:** SLAM not publishing map data
- **Solution:** Verify `use_sim_time:=true` is set and Gazebo is publishing `/clock` topic

**Issue:** Robot not appearing in simulation
- **Solution:** Check that `~/clearpath/robot.yaml` exists and is properly configured

---

## License

This repository maintains compatibility with the original [Clearpath Simulator](https://github.com/clearpathrobotics/clearpath_simulator) and respects all AWS RoboMaker world licenses.

## Resources

- [ROS 2 Humble Documentation](https://docs.ros.org/en/humble/)
- [Ignition Gazebo Documentation](https://gazebosim.org/)
- [Cartographer SLAM](https://github.com/cartographer-project/cartographer_ros)
- [Original Clearpath Simulator](https://github.com/clearpathrobotics/clearpath_simulator)
- [AWS RoboMaker Worlds](https://github.com/aws-robotics)

---

**Note:** This is a community-maintained fork. For issues with the base simulator, see the [original repository](https://github.com/clearpathrobotics/clearpath_simulator/tree/humble). For AWS world-specific issues, refer to the [AWS RoboMaker repositories](https://github.com/aws-robotics).
