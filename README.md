# jimmBOT Robot (Infra)

Devcontainer and workspace bootstrap for jimmBOT on ROS 2 kilted.

## Dependencies

Before starting, make sure the following are installed on your host machine:

- **Docker**
- **VS Code**
- **Dev Containers extension**
- **NVIDIA Container Toolkit**: If you want NVIDIA Gpu in the container

## Quick start

Use VS Code with the Dev Containers extension installed.

```bash
git clone git@github.com:mh-Robotics/jimmbot_robot.git
cd jimmbot_robot
code .
```

Then reopen the folder in the container.

> Note: The full workspace is available under `/workspaces`, while cloned repos and build data stay persisted on the host in `.meta_workspaces/` across container rebuilds.

## VS Code tasks

Below is a list of tasks configured for this project:

- **Setup Workspace**: Sets up the workspace

- **Clean Setup Workspace**: Refreshes workspace links and checks repos

- **Build**: Builds the workspace

- **Clean Build**: Cleans and rebuilds the workspace

- **Build Package**: Builds one selected package

- **Launch jimmbot View GZ**: Launches the jimmBOT visualization stack with Gazebo

- **Kill All ROS/Gazebo Instances**: Stops any running ROS 2, Gazebo, bridge, and RViz processes from previous sessions

## SSH auth (1Password optional)

This setup supports both styles:

- SSH agent forwarding (works with 1Password SSH agent if that is your active host agent).
- `~/.ssh` mount fallback for users not using 1Password.
