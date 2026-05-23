## Lidar Sim Docker

Docker image and Dev Container setup for ROS 2 Jazzy with Gazebo Harmonic and optional VNC desktop access.

### What is included
- Ubuntu 24.04 base
- ROS 2 Jazzy (`ros-jazzy-desktop`) and `ros-jazzy-ros-gz`
- VNC + XFCE desktop (optional)
- ROS 2 workspace mounted at `/root/ros2_ws`

### Prerequisites
- Docker Desktop (macOS/Windows) or Docker Engine (Linux)
- Optional: VS Code + Dev Containers extension
- Optional: VNC client (RealVNC, TigerVNC, etc.)

### Build the image locally
```bash
docker build -t ros2-jazzy-gz-vnc:local -f Dockerfile .
```

### Run the container
```bash
docker run --rm -it \
	--name ros2-jazzy-gazebo-vnc \
	--shm-size=2g \
	-p 5901:5901 \
	-v "$PWD/ros2_ws:/root/ros2_ws" \
	-v "$PWD:/root/project" \
	-w /root/project \
	ros2-jazzy-gz-vnc:local \
	bash
```

Or using the images from repo
```bash
docker run --rm -it \
  	--name ros2-jazzy-gazebo-vnc \
  	--shm-size=2g \
  	-p 5901:5901 \
  	-v "$PWD/ros2_ws:/root/ros2_ws" \
	-v "$PWD:/root/project" \
  	-w /root/project \
  	docker.io/ninhnt/ros2-jazzy-gazebo-vnc:latest \
	bash
```

The container stays running and sources ROS automatically.

If you want to open a new terminal that connect to that running container, using this command:
```bash
docker exec -it ros2-jazzy-gazebo-vnc bash
```

### Start VNC (GUI)
VNC is not started by default. Start it inside the container:
```bash
start-vnc
```

Then connect from your host to `localhost:5901`. The default password is `1234`.

You can also auto-start VNC on container launch:
```bash
docker run --rm -it \
	--shm-size=2g \
	-p 5901:5901 \
	-e START_VNC=1 \
	-v "$PWD/ros2_ws:/root/ros2_ws" \
	-v "$PWD:/root/project" \
	ros2-jazzy-gz-vnc:local
```

VNC-related environment variables (defaults shown):
- `DISPLAY=:1`
- `VNC_PASSWORD=1234`
- `VNC_GEOMETRY=1920x1080` (entrypoint defaults to `1280x720` if not set)
- `VNC_DEPTH=24`

### Use VS Code Dev Containers
This repo includes a `.devcontainer/devcontainer.json` that pulls a prebuilt image.

1. Open the folder in VS Code.
2. Run: `Dev Containers: Reopen in Container`.
3. The ROS workspace is mounted at `/root/ros2_ws`.

To use your locally built image instead, edit `.devcontainer/devcontainer.json` and enable the `build` section.

### ROS 2 workspace
The workspace is mounted from `./ros2_ws` and already sourced in the container shell. Example:
```bash
cd /root/ros2_ws
colcon build
```

### Notes
- Docker Desktop on macOS/Windows uses software OpenGL in this image (`LIBGL_ALWAYS_SOFTWARE=1`).
- If VNC fails to start, check that port `5901` is free on the host.
