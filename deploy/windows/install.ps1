#Requires -Version 5.1
[CmdletBinding()]
param([switch]$Silent)

$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an elevated (Administrator) PowerShell.'
}

$arch = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
$installer = Join-Path $PSScriptRoot "bin\$arch\wdi-simple.exe"
if (-not (Test-Path -LiteralPath $installer)) { throw "Missing installer: $installer" }

$devices = @(
    @{ Pid = '0x0013'; Name = 'Xilinx Platform Cable USB II (bootloader)' },
    @{ Pid = '0x000d'; Name = 'Xilinx Platform Cable USB embedded (bootloader)' },
    @{ Pid = '0x0008'; Name = 'Xilinx Platform Cable USB (firmware loaded)' }
)

foreach ($device in $devices) {
    $pidText = $device.Pid.Substring(2)
    $destination = Join-Path $PSScriptRoot "driver\03fd_$pidText"
    $arguments = @(
        '--vid', '0x03fd', '--pid', $device.Pid,
        '--type', '0', '--manufacturer', 'Xilinx', '--name', $device.Name,
        '--dest', $destination, '--inf', "xpcu_$pidText.inf"
    )
    if ($Silent) { $arguments += '--silent' }
    Write-Host "Installing WinUSB for 03fd:$pidText ..."
    & $installer @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "WinUSB installation failed for 03fd:$pidText (exit code $LASTEXITCODE)."
    }
}

Write-Host 'WinUSB packages installed. Unplug and reconnect the cable.' -ForegroundColor Green
Write-Host 'The cable may enumerate twice while firmware loads; both identities are covered.'

$initialized = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
    Where-Object InstanceId -Match '^USB\\VID_03FD&PID_0008'
if (-not $initialized) {
    Write-Warning 'The 03fd:0008 package was staged while that identity was disconnected.'
    Write-Warning 'If Windows retains an older driver after the first firmware upload, run this installer again while 03fd:0008 is visible.'
}
