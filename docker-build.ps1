$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

docker compose version *> $null
if ($LASTEXITCODE -eq 0) {
    $compose = @('docker', 'compose')
} elseif (Get-Command docker-compose -ErrorAction SilentlyContinue) {
    $compose = @('docker-compose')
} else {
    throw 'Docker Compose v2 or docker-compose is required.'
}

try {
    if ($compose.Count -eq 2) {
        & $compose[0] $compose[1] up --build --abort-on-container-exit --exit-code-from package package
    } else {
        & $compose[0] up --build --abort-on-container-exit --exit-code-from package package
    }
    if ($LASTEXITCODE -ne 0) { throw "Docker package build failed with exit code $LASTEXITCODE" }
} finally {
    if ($compose.Count -eq 2) {
        & $compose[0] $compose[1] down --remove-orphans
    } else {
        & $compose[0] down --remove-orphans
    }
}

