# Detailed Guide: AWS Small House World Integration

This guide provides the complete sequence of operations to install, configure, and run the **AWS RoboMaker Small House World** within the Clearpath Gazebo Sim environment.

## 1. Initial Repository Setup
Navigate to the root of the ROS2 workspace and clone the repository:
```bash
cd ~/clearpath_ws
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-small-house-world.git src/aws-robomaker-small-house-world
```

## 2. Model Preparation & Fixes
The models in this repository require specific adjustments to run correctly in Gazebo Sim (Ignition).

### A. Update Model URIs
Standardize all mesh references:
```bash
find src/aws-robomaker-small-house-world/models -name "model.sdf" -exec sed -i 's|file://models/|model://|g' {} +
```

### B. Fix Invalid Inertias & Static Status
Remove `<inertial>` tags and force `<static>true</static>` for all house models to ensure stability.

### C. Fix Texture Paths & Photo Synchronization
- Update texture paths in `.DAE` files from `../../../../photos/` to `../../../photos/`.
- **Note:** This world shares models with the hospital world. Synchronize the `photos` directories:
```bash
cp -n src/aws-robomaker-small-house-world/photos/* src/aws-robomaker-hospital-world/photos/
cp -n src/aws-robomaker-hospital-world/photos/* src/aws-robomaker-small-house-world/photos/
```

## 3. World Conversion (.world to .sdf)
Convert the original `.world` file to a Gazebo Sim compatible `.sdf` file in `src/clearpath_simulator/clearpath_gz/worlds/small_house.sdf`. Include standard plugins and spherical coordinates.

## 4. Launch Configuration Updates
Modify `src/clearpath_simulator/clearpath_gz/launch/gz_sim.launch.py` to include the house resource paths.

```python
# AWS Small House World
aws_house_pkg = os.path.join(workspace_src, 'aws-robomaker-small-house-world')
aws_house_models = os.path.join(aws_house_pkg, 'models')
aws_house_photos = os.path.join(aws_house_pkg, 'photos')

packages_paths.extend([aws_house_pkg, aws_house_models, aws_house_photos])
```

## 5. Build
Build the workspace:
```bash
colcon build --packages-select clearpath_gz aws_robomaker_small_house_world --symlink-install --allow-overriding clearpath_gz
```

## 6. Running the Simulation
Source the workspace and launch the simulation:
```bash
source install/setup.bash
ros2 launch clearpath_gz simulation.launch.py world:=small_house
```
