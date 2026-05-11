# Detailed Guide: Integrating AWS Hospital World into Clearpath Simulator

This guide provides the complete sequence of operations to install, configure, and run the **AWS RoboMaker Hospital World** within the Clearpath Gazebo Sim environment.

## 1. Initial Repository Setup
Navigate to the root of the ROS2 workspace and clone the repository:
```bash
cd ~/clearpath_ws
git clone -b ros2 https://github.com/aws-robotics/aws-robomaker-hospital-world.git src/aws-robomaker-hospital-world
```

## 2. Dependency Installation
The model download script requires specific Python libraries:
```bash
pip install docopt requests lxml
```

Install system dependencies via `rosdep`:
```bash
rosdep install --from-paths src/aws-robomaker-hospital-world --ignore-src -r -y
```

## 3. Model Preparation
Download the high-fidelity 3D models from Ignition Fuel:
```bash
python3 src/aws-robomaker-hospital-world/fuel_utility.py download \
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
  -d src/aws-robomaker-hospital-world/fuel_models --verbose
```

Fix the relative texture paths in the COLLADA (`.DAE`) files to ensure they resolve within the local package structure:
```bash
find src/aws-robomaker-hospital-world/models -name "*.DAE" -exec sed -i 's|../../../../photos/|../../../photos/|g' {} +
```

## 4. World Conversion (.world to .sdf)
Original AWS worlds are designed for Gazebo Classic. For Gazebo Sim, follow these conversion steps:

1. Create a new file in `src/clearpath_simulator/clearpath_gz/worlds/` (e.g., `hospital.sdf`).
2. Start the file with the SDF 1.7 header and include essential plugins:
    - `ignition::gazebo::systems::Physics`
    - `ignition::gazebo::systems::UserCommands`
    - `ignition::gazebo::systems::SceneBroadcaster`
    - `ignition::gazebo::systems::Sensors`
    - `ignition::gazebo::systems::Imu`
    - `ignition::gazebo::systems::NavSat`
3. Set the Sun URI to: `https://fuel.gazebosim.org/1.0/OpenRobotics/models/Sun`
4. Add a `<spherical_coordinates>` block to enable GPS/NavSat sensors:
   ```xml
    <spherical_coordinates>
      <surface_model>EARTH_WGS84</surface_model>
      <world_frame_orientation>ENU</world_frame_orientation>
      <latitude_deg>-22.986687</latitude_deg>
      <longitude_deg>-43.202501</longitude_deg>
      <elevation>0</elevation>
      <heading_deg>0</heading_deg>
    </spherical_coordinates>
   ```
5. Copy the model includes from the original `.world` file, but omit the classic Gazebo plugins and the default Sun/Ground Plane.

## 5. Launch Configuration Updates
Edit `src/clearpath_simulator/clearpath_gz/launch/gz_sim.launch.py` to export the new resource paths. Locate the `generate_launch_description` function and add logic to include:
- The hospital package root
- The `models` directory
- The `fuel_models` directory
- The `photos` directory

This ensures that the Gazebo Server and GUI can resolve model URIs and textures.

## 6. Package and Build Configuration
Update `src/aws-robomaker-hospital-world/CMakeLists.txt` to install the `photos` and `fuel_models` directories:
```cmake
install(DIRECTORY launch models fuel_models worlds photos
	DESTINATION share/${PROJECT_NAME}
)
```

Build the workspace:
```bash
colcon build --packages-select clearpath_gz aws_robomaker_hospital_world --symlink-install --allow-overriding clearpath_gz
```

## 7. Running the Simulation
Source the workspace and launch the simulation:
```bash
source install/setup.bash
ros2 launch clearpath_gz simulation.launch.py world:=hospital
```

Repeat for `hospital_two_floors` or `hospital_three_floors` if those files were created.
