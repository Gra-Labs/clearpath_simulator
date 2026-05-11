"""
Copyright 2018 The Cartographer Authors
Copyright 2022 Wyca Robotics (for the ros2 conversion)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, OpaqueFunction, Shutdown
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
import os


def generate_launch_description():
    ## ***** Launch arguments *****
    load_state_filename_arg = DeclareLaunchArgument("load_state_filename")

    def launch_setup(context, *args, **kwargs):
        load_state_filename = LaunchConfiguration("load_state_filename").perform(context)
        
        config_dir = "/home/retia/clearpath_ws/src"
        config_file = "clearpath_3d_localization.lua"

        cartographer_node = Node(
            package="cartographer_ros",
            executable="cartographer_node",
            parameters=[{"use_sim_time": True}],
            arguments=[
                "-configuration_directory", config_dir,
                "-configuration_basename", config_file,
                "-load_state_filename", load_state_filename,
            ],
            remappings=[
                ("points2", "/j100_0000/sensors/lidar3d_0/points"),
                ("imu", "/j100_0000/sensors/imu_0/data"),
                ("tf", "/j100_0000/tf"),
                ("tf_static", "/j100_0000/tf_static"),
            ],
            output="screen",
        )

        cartographer_occupancy_grid_node = Node(
            package="cartographer_ros",
            executable="cartographer_occupancy_grid_node",
            parameters=[{"use_sim_time": True}, {"resolution": 0.05}],
        )

        rviz_node = Node(
            package="rviz2",
            executable="rviz2",
            on_exit=Shutdown(),
            arguments=[
                "-d",
                "/home/retia/clearpath_ws/src/clearpath_cartographer.rviz",
            ],
            parameters=[{"use_sim_time": True}],
            remappings=[
                ("tf", "/j100_0000/tf"),
                ("tf_static", "/j100_0000/tf_static"),
            ],
        )

        return [
            cartographer_node,
            cartographer_occupancy_grid_node,
            rviz_node,
        ]

    return LaunchDescription(
        [
            load_state_filename_arg,
            OpaqueFunction(function=launch_setup)
        ]
    )
