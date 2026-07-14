$devices = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object InstanceId -Match '^USB\\VID_03FD&PID_(0013|000D|0008)'

if ($devices) {
    $devices | Select-Object Status, Class, FriendlyName, InstanceId | Format-Table -AutoSize
} else {
    Write-Warning 'No connected Xilinx Platform Cable USB device was found (VID 03fd).'
    exit 1
}

