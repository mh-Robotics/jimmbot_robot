# jimmbot workspace plan

## Current facts

- Root symlinks already exist: `/workspaces/build`, `/workspaces/install`, `/workspaces/log`.
- They were hidden by VS Code `files.exclude`, not missing from the workspace.
- RViz2 core packages are already installed.
- `joint_state_broadcaster`, `joint_state_publisher`, and OpenNI-related ROS packages are not installed yet.
- `clangd` is not on PATH yet, so compile database generation needs to be paired with the editor/tool install decision.

## Phase 1: workspace and editor

- [x] Unhide `build`, `install`, and `log` in the workspace explorer.
- [x] Disable Microsoft C/C++ IntelliSense in workspace settings.
- [x] Remove `c_cpp_properties.json` so clangd becomes the single C/C++ source of truth.
- [x] Make build tasks export CMake compile commands.
- [x] Merge per-package compile databases into `/workspaces/build/compile_commands.json`.
- [ ] Install and enable clangd tooling if it is still missing in the container/editor.

## Phase 2: dependency audit and install

- [ ] Record the current ROS package baseline for RViz, Gazebo, ros_gz, control, OpenNI, and sensor plugins.
- [ ] Install the missing ROS 2 packages for joint-state publishing/broadcasting and Kinect/OpenNI support.
- [ ] Verify package names available on this distro before editing package manifests or launch files.
- [ ] Capture the final installed package list in repo notes so the environment is reproducible.

## Phase 3: Gazebo sensor and control path

- [ ] Verify whether Gazebo joint states should continue to come from the Gazebo JointStatePublisher system or move to `ros2_control` + `joint_state_broadcaster` once packages are installed.
- [ ] Audit Kinect and other sensor plugins in the description/Gazebo xacros for ROS 2 compatibility only.
- [ ] Align Gazebo sensor bridges with the actual topics published by the model.
- [ ] Re-test depth image, IMU, lidar, GPS, and joint state topics after package installation.

## Phase 4: visualization and TF stability

- [ ] Re-validate `jimmbot_view_robot.launch.py` and `jimmbot_view_gz.launch.py` on a clean process table only.
- [ ] Confirm RViz RobotModel status with one Gazebo world and one `robot_state_publisher`.
- [ ] Keep `use_sim_time` consistent across RViz, robot_state_publisher, and TF debugging tools.
- [ ] Re-check depth displays, TF tree continuity, and wheel/Kinect transforms after the package audit.

## Phase 5: description and gazebo cleanup

- [ ] Remove remaining ROS 1-era configuration that is no longer part of the ROS 2 bringup path.
- [ ] Audit `jimmbot_description`, `jimmbot_gazebo`, and `jimmbot_controller` manifests and launch dependencies.
- [ ] Keep the world-name fix in the combined RViz+Gazebo launch and verify empty/simple world defaults.
- [ ] Document one clean start command and one clean stop command for future debugging.

## Notes on current warnings

- `libEGL ... failed to open /dev/dri/renderD128` is a container GPU/device access warning, not a URDF or TF bug.
- `QStandardPaths: XDG_RUNTIME_DIR not set` is common in this container and is not the root cause of the RViz/Gazebo TF issues.

## Prepare host

# Install NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
ros2 launch jimmbot_viz jimmbot_view_gz.launch.py

Target repos to keep as-is

jimmbot_description
jimmbot_gazebo
jimmbot_viz
jimmbot_robot
jimmbot_msgs
New grouped repos for the rest

jimmbot_controllers
Keep existing jimmbot_controller package (or rename repo only, package can stay same for now)
Move jimmbot_bringup here
Move jimmbot_navigation here
Move jimmbot_audiofx here (fits behavior/runtime orchestration side)
jimmbot_hardware
Move jimmbot_base here
Move jimmbot_sensors here
Move jimmbot_middleware here


<!-- EOF -->

