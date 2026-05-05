FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# VNC defaults.
# VNC will NOT start automatically. Run start-vnc when you need GUI.
ENV DISPLAY=:1
ENV VNC_PASSWORD=1234
ENV VNC_GEOMETRY=1920x1080
ENV VNC_DEPTH=24

# Helpful for Gazebo/RViz in Docker Desktop on macOS/Windows
ENV QT_X11_NO_MITSHM=1
ENV LIBGL_ALWAYS_SOFTWARE=1

# ------------------------------------------------------------
# Use a faster Ubuntu mirror.
# This only changes Ubuntu apt mirrors, not all HTTPS URLs.
# ------------------------------------------------------------
RUN sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.kernel.org/ubuntu/|g' \
    -e 's|http://security.ubuntu.com/ubuntu/|http://mirrors.kernel.org/ubuntu/|g' \
    /etc/apt/sources.list.d/ubuntu.sources

# ------------------------------------------------------------
# Make apt less likely to hang forever.
# This does not replace HTTPS with HTTP.
# ------------------------------------------------------------
RUN printf 'Acquire::Retries "3";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\n' \
    > /etc/apt/apt.conf.d/99network-fixes

# ------------------------------------------------------------
# Basic dependencies
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    lsb-release \
    software-properties-common \
    git \
    build-essential \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Add ROS 2 Jazzy apt source
# ------------------------------------------------------------
RUN add-apt-repository -y universe && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu noble main" \
    > /etc/apt/sources.list.d/ros2.list

# ------------------------------------------------------------
# Install ROS 2 Jazzy + Gazebo Harmonic integration
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    ros-jazzy-desktop \
    ros-jazzy-ros-gz \
    python3-rosdep \
    python3-pip \
    python3-colcon-common-extensions \
    python3-vcstool \
    && rosdep init || true \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Install TigerVNC + XFCE + GUI/OpenGL support
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    tigervnc-standalone-server \
    tigervnc-common \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    x11-xserver-utils \
    mesa-utils \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libxcb-cursor0 \
    libxkbcommon-x11-0 \
    libxcb-xinerama0 \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Source ROS automatically in bash
# ------------------------------------------------------------
RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /root/ros2_ws/install/setup.bash ]; then source /root/ros2_ws/install/setup.bash; fi" >> /root/.bashrc && \
    echo "export DISPLAY=:1" >> /root/.bashrc

# ------------------------------------------------------------
# Add helper command: start-vnc
# VNC/XFCE will start only when you run this command.
# ------------------------------------------------------------
RUN cat > /usr/local/bin/start-vnc << 'EOF'
#!/usr/bin/env bash
set -e

export DISPLAY=${DISPLAY:-:1}
export VNC_PASSWORD=${VNC_PASSWORD:-1234}
export VNC_GEOMETRY=${VNC_GEOMETRY:-1920x1080}
export VNC_DEPTH=${VNC_DEPTH:-24}
export QT_X11_NO_MITSHM=${QT_X11_NO_MITSHM:-1}
export LIBGL_ALWAYS_SOFTWARE=${LIBGL_ALWAYS_SOFTWARE:-1}

DISPLAY_NUM="${DISPLAY#:}"
DISPLAY_NUM="${DISPLAY_NUM%%.*}"

mkdir -p /root/.vnc

echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

cat > /root/.vnc/xstartup << 'XEOF'
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export DESKTOP_SESSION=xfce

export QT_X11_NO_MITSHM=1
export LIBGL_ALWAYS_SOFTWARE=1

dbus-launch --exit-with-session startxfce4
XEOF

chmod +x /root/.vnc/xstartup

vncserver -kill "$DISPLAY" >/dev/null 2>&1 || true
rm -f "/tmp/.X${DISPLAY_NUM}-lock"
rm -f "/tmp/.X11-unix/X${DISPLAY_NUM}"

vncserver "$DISPLAY" \
    -geometry "$VNC_GEOMETRY" \
    -depth "$VNC_DEPTH" \
    -localhost no \
    -SecurityTypes VncAuth \
    -AlwaysShared

echo "=================================================="
echo "VNC started."
echo "Connect from VNC Viewer:"
echo "  localhost:5901"
echo ""
echo "Password:"
echo "  $VNC_PASSWORD"
echo ""
echo "DISPLAY:"
echo "  $DISPLAY"
echo "=================================================="
EOF

RUN chmod +x /usr/local/bin/start-vnc

WORKDIR /root/ros2_ws

EXPOSE 5901

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Keep container alive for VS Code Dev Containers
CMD ["bash", "-lc", "tail -f /dev/null"]