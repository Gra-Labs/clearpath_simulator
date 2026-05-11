# Detailed Guide: AWS Racetrack World Integration

This guide provides the complete sequence of operations to install, configure, and run the **AWS RoboMaker Racetrack World** within the Clearpath Gazebo Sim environment.

## 1. Initial Repository Setup
Navigate to the root of the ROS2 workspace and clone the repository:
```bash
cd ~/clearpath_ws
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-racetrack-world.git src/aws-robomaker-racetrack-world
```

## 2. Model Preparation & Fixes
The models in this repository require specific adjustments to run correctly in Gazebo Sim (Ignition).

### A. Update Model URIs
Standardize all mesh references:
```bash
find src/aws-robomaker-racetrack-world/models -name "model.sdf" -exec sed -i 's|file://models/|model://|g' {} +
```

### B. Fix Invalid Inertias
Remove `<inertial>` tags from all static models to prevent loading errors in Gazebo Sim.

## 3. World Conversion (.world to .sdf)
Convert the original `.world` file to a Gazebo Sim compatible `.sdf` file in `src/clearpath_simulator/clearpath_gz/worlds/racetrack.sdf`. 

**Warning:** The Racetrack world usually includes its own sun and lighting definitions. Avoid adding a duplicate sun include during conversion. Include standard plugins and spherical coordinates for GPS support.

## 4. Launch Configuration Updates
Modify `src/clearpath_simulator/clearpath_gz/launch/gz_sim.launch.py` to include the racetrack resource paths.

```python
# AWS Racetrack World
aws_racetrack_pkg = os.path.join(workspace_src, 'aws-robomaker-racetrack-world')
aws_racetrack_models = os.path.join(aws_racetrack_pkg, 'models')

packages_paths.extend([aws_racetrack_pkg, aws_racetrack_models])
```

## 5. Build
Build the workspace:
```bash
colcon build --packages-select clearpath_gz aws_robomaker_racetrack_world --symlink-install --allow-overriding clearpath_gz
```

## 6. Running the Simulation
Source the workspace and launch the simulation:
```bash
source install/setup.bash
ros2 launch clearpath_gz simulation.launch.py world:=racetrack
```
