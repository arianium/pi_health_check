#!/usr/bin/env bash
set -u

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${PROJECT_DIR}/.env"

if [[ ! -r "$ENV_FILE" ]]; then
    echo "ERROR: missing ${ENV_FILE}" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${HEARTBEAT_URL:-}" ]]; then
    echo "ERROR: HEARTBEAT_URL is not configured in ${ENV_FILE}" >&2
    exit 1
fi

INTERVAL="${HEARTBEAT_INTERVAL_SECONDS:-60}"
TIMEOUT="${HEARTBEAT_TIMEOUT_SECONDS:-20}"

echo "Pi health checker started; heartbeat interval=${INTERVAL}s timeout=${TIMEOUT}s"

while true; do
    timestamp="$(date --iso-8601=seconds)"

    if curl \
        --fail \
        --silent \
        --show-error \
        --max-time "$TIMEOUT" \
        --output /dev/null \
        "$HEARTBEAT_URL"
    then
        echo "${timestamp} heartbeat OK"
    else
        # Do not terminate: a network outage is exactly what this service is
        # expected to survive. UptimeRobot will detect the missing heartbeat.
        echo "${timestamp} heartbeat FAILED; will retry in ${INTERVAL}s" >&2
    fi

    sleep "$INTERVAL"
done
