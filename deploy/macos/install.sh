#!/usr/bin/env sh
set -eu

if [ "$(uname -s)" != Darwin ]; then
    echo 'This helper must be run on macOS.' >&2
    exit 2
fi

if system_profiler SPUSBDataType 2>/dev/null | grep -qi '0x03fd'; then
    echo 'Found a connected Xilinx USB device (vendor 0x03fd).'
else
    echo 'No connected Xilinx USB device (vendor 0x03fd) was found.' >&2
fi

if command -v brew >/dev/null 2>&1; then
    brew list libusb >/dev/null 2>&1 || brew install libusb
else
    echo 'Homebrew is not installed. Install libusb using your preferred package manager.' >&2
fi

cat <<'EOF'
macOS uses its native USB stack through libusb; there is no XPCU kernel driver to install.
Install/build openFPGALoader with libusb support, then run:
  openFPGALoader --cable xilinxPlatformCableUsb --detect
EOF
