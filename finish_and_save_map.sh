#!/bin/bash

# Clearpath SLAM Automation: Finish and Save
# This script closes the current SLAM trajectory and saves both the .pbstream and 2D map.

if [ -z "$1" ]; then
    NAME="hospital_map"
else
    NAME=$1
fi

WS_ROOT="/home/retia/clearpath_ws"
MAP_DIR="$WS_ROOT/src"

echo "🏁 Finalizing SLAM Trajectory..."
ros2 service call /finish_trajectory cartographer_ros_msgs/srv/FinishTrajectory "{trajectory_id: 0}"

echo "💾 Saving full SLAM state (.pbstream)..."
ros2 service call /write_state cartographer_ros_msgs/srv/WriteState "{filename: '$MAP_DIR/$NAME.pbstream', include_unfinished_submaps: true}"

echo "🖼️ Saving 2D Navigation map (.yaml/.pgm)..."
ros2 run nav2_map_server map_saver_cli -f $MAP_DIR/$NAME

echo "✅ Map saved to $MAP_DIR/$NAME"
