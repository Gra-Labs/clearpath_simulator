# Detailed Guide: AWS Bookstore World Integration

This guide provides the complete sequence of operations to install, configure, and run the **AWS RoboMaker Bookstore World** within the Clearpath Gazebo Sim environment.

## 1. Initial Repository Setup
Navigate to the root of the ROS2 workspace and clone the repository:
```bash
cd ~/clearpath_ws
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-bookstore-world.git src/aws-robomaker-bookstore-world
```

## 2. Model Preparation & Fixes
The models in this repository require specific adjustments to run correctly in Gazebo Sim (Ignition).

### A. Update Model URIs
Ensure models reference assets using the `model://` scheme:
```bash
find src/aws-robomaker-bookstore-world/models -name "model.sdf" -exec sed -i 's|file://models/|model://|g' {} +
```

### B. Fix Invalid Inertias
Remove `<inertial>` tags from all models marked as `<static>1</static>` to prevent loading errors.

### C. Fix Case-Sensitivity Issues
AWS models often have case mismatches between the SDF URI and the actual filename on disk. A script should be used to verify filenames in the `meshes` directory and update the SDF URIs to match the exact case.

## 3. World Conversion (.world to .sdf)
Convert the original `.world` file to a Gazebo Sim compatible `.sdf` file in `src/clearpath_simulator/clearpath_gz/worlds/bookstore.sdf`.

Ensure the following plugins are included:
- `ignition::gazebo::systems::Physics`
- `ignition::gazebo::systems::UserCommands`
- `ignition::gazebo::systems::SceneBroadcaster`
- `ignition::gazebo::systems::Sensors`
- `ignition::gazebo::systems::Imu`
- `ignition::gazebo::systems::NavSat`

Include a `<spherical_coordinates>` block for GPS support.

## 4. Launch Configuration Updates
Modify `src/clearpath_simulator/clearpath_gz/launch/gz_sim.launch.py` to include the new resource paths.

```python
# AWS Bookstore World
aws_bookstore_pkg = os.path.join(workspace_src, 'aws-robomaker-bookstore-world')
aws_bookstore_models = os.path.join(aws_bookstore_pkg, 'models')

packages_paths.extend([aws_bookstore_pkg, aws_bookstore_models])
```

## 5. Build
Build the workspace:
```bash
colcon build --packages-select clearpath_gz aws_robomaker_bookstore_world --symlink-install --allow-overriding clearpath_gz
```

## 6. Running the Simulation
Source the workspace and launch the simulation:
```bash
source install/setup.bash
ros2 launch clearpath_gz simulation.launch.py world:=bookstore
```
