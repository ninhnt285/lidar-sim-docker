#!/usr/bin/env bash
set -e

source /opt/ros/${ROS_DISTRO}/setup.bash

if [ -f /root/ros2_ws/install/setup.bash ]; then
    source /root/ros2_ws/install/setup.bash
fi

export DISPLAY=${DISPLAY:-:1}
export VNC_PASSWORD=${VNC_PASSWORD:-1234}
export VNC_GEOMETRY=${VNC_GEOMETRY:-1280x720}
export VNC_DEPTH=${VNC_DEPTH:-24}
export QT_X11_NO_MITSHM=${QT_X11_NO_MITSHM:-1}
export LIBGL_ALWAYS_SOFTWARE=${LIBGL_ALWAYS_SOFTWARE:-1}

start_vnc() {
    DISPLAY_NUM="${DISPLAY#:}"
    DISPLAY_NUM="${DISPLAY_NUM%%.*}"

    mkdir -p /root/.vnc

    echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
    chmod 600 /root/.vnc/passwd

    cat > /root/.vnc/xstartup << 'EOF'
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xfce
export DESKTOP_SESSION=xfce

export QT_X11_NO_MITSHM=1
export LIBGL_ALWAYS_SOFTWARE=1

dbus-launch --exit-with-session startxfce4
EOF

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
    echo "Connect to: localhost:5901"
    echo "Password: $VNC_PASSWORD"
    echo "DISPLAY: $DISPLAY"
    echo "=================================================="
}

if [ "${START_VNC:-0}" = "1" ]; then
    start_vnc
else
    echo "VNC is not started. To start it manually, run:"
    echo "  start-vnc"
fi

exec "$@"