#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
if docker compose version >/dev/null 2>&1; then
    compose='docker compose'
elif command -v docker-compose >/dev/null 2>&1; then
    compose='docker-compose'
else
    echo 'Docker Compose v2 or docker-compose is required.' >&2
    exit 1
fi

cleanup() {
    $compose down --remove-orphans
}
trap cleanup EXIT INT TERM

$compose up --build --abort-on-container-exit --exit-code-from package package
