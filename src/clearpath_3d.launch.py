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
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, OpaqueFunction
from launch.conditions import IfCondition, UnlessCondition
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node, SetRemap
from launch_ros.substitutions import FindPackageShare
from launch.launch_description_sources import PythonLaunchDescriptionSource
import os


def generate_launch_description():

    ## ***** Launch arguments *****
    use_sim_time_arg = DeclareLaunchArgument("use_sim_time", default_value="False")
    load_state_filename_arg = DeclareLaunchArgument("load_state_filename", default_value="")
    resolution_arg = DeclareLaunchArgument("resolution", default_value="0.05")
    rviz_arg = DeclareLaunchArgument("rviz", default_value="false")

    def launch_setup(context, *args, **kwargs):
        use_sim_time = LaunchConfiguration("use_sim_time")
        load_state_filename = LaunchConfiguration("load_state_filename").perform(context)
        resolution = LaunchConfiguration("resolution")
        rviz = LaunchConfiguration("rviz").perform(context)

        config_dir = "/home/retia/clearpath_ws/src"
        config_file = "clearpath_3d.lua"

        node_args = [
            "-configuration_directory", config_dir,
            "-configuration_basename", config_file,
        ]

        if load_state_filename:
            node_args.extend(["-load_state_filename", load_state_filename])

        cartographer_node = Node(
            package="cartographer_ros",
            executable="cartographer_node",
            parameters=[{"use_sim_time": use_sim_time}],
            arguments=node_args,
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
            parameters=[
                {"use_sim_time": use_sim_time},
                {"resolution": resolution}
            ],
        )

        rviz_node = Node(
            package="rviz2",
            executable="rviz2",
            arguments=["-d", os.path.join(config_dir, "clearpath_cartographer.rviz")],
            parameters=[{"use_sim_time": use_sim_time}],
            remappings=[
                ("tf", "/j100_0000/tf"),
                ("tf_static", "/j100_0000/tf_static"),
            ],
            condition=IfCondition(rviz),
        )

        return [
            cartographer_node,
            cartographer_occupancy_grid_node,
            rviz_node,
        ]

    return LaunchDescription(
        [
            use_sim_time_arg,
            load_state_filename_arg,
            resolution_arg,
            rviz_arg,
            OpaqueFunction(function=launch_setup)
        ]
    )
