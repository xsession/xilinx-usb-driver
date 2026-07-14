#!/usr/bin/env bash
set -euo pipefail

output_dir=${OUTPUT_DIR:-/out}
work_dir=/tmp/xpcu-package

rm -rf "$work_dir"
mkdir -p "$work_dir" "$output_dir"

copy_docs() {
    cp /work/DEPLOYMENT.md "$1/README.md"
}

linux_root="$work_dir/xilinx-platform-cable-linux"
mkdir -p "$linux_root/lib/x86_64" "$linux_root/lib/i686"
cp -a /work/deploy/linux/. "$linux_root/"
cp /artifacts/linux-x64/*.so "$linux_root/lib/x86_64/"
cp /artifacts/linux-x86/*.so "$linux_root/lib/i686/"
copy_docs "$linux_root"

windows_root="$work_dir/xilinx-platform-cable-windows"
mkdir -p "$windows_root/bin/x64" "$windows_root/bin/x86"
cp -a /work/deploy/windows/. "$windows_root/"

for arch in x64 x86; do
    archive=$(find /libwdi-dist -maxdepth 1 -type f -name "libwdi-*-${arch}.zip" | sort | tail -n 1)
    if [[ -z "$archive" ]]; then
        echo "Missing Docker-built libwdi archive for $arch in /libwdi-dist" >&2
        exit 1
    fi
    unzip -j -q "$archive" '*/bin/wdi-simple.exe' -d "$windows_root/bin/$arch"
done
copy_docs "$windows_root"

macos_root="$work_dir/xilinx-platform-cable-macos"
mkdir -p "$macos_root"
cp -a /work/deploy/macos/. "$macos_root/"
copy_docs "$macos_root"

for platform in linux windows macos; do
    name="xilinx-platform-cable-${platform}"
    rm -f "$output_dir/$name.zip" "$output_dir/$name.zip.sha256"
    (
        cd "$work_dir"
        find "$name" -type f -print | LC_ALL=C sort | zip -X -q "$output_dir/$name.zip" -@
    )
    (
        cd "$output_dir"
        sha256sum "$name.zip" > "$name.zip.sha256"
    )
    echo "Created $output_dir/$name.zip"
done

