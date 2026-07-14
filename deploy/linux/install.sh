#!/usr/bin/env sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

src=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/99-xilinx-platform-cable.rules
dst=/etc/udev/rules.d/99-xilinx-platform-cable.rules
install -m 0644 "$src" "$dst"

if command -v udevadm >/dev/null 2>&1; then
    udevadm control --reload-rules
    udevadm trigger --subsystem-match=usb --attr-match=idVendor=03fd || true
fi

echo "Installed $dst"
echo 'Unplug and reconnect the Xilinx cable before using openFPGALoader.'

