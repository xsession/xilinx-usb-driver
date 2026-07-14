#!/usr/bin/env sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

rm -f /etc/udev/rules.d/99-xilinx-platform-cable.rules
if command -v udevadm >/dev/null 2>&1; then
    udevadm control --reload-rules
fi
echo 'Removed the Xilinx Platform Cable udev rule.'

