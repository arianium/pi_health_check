#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${PROJECT_DIR}/.env"
SERVICE_NAME="pi-health-check.service"
USER_UNIT_DIR="${HOME}/.config/systemd/user"
USER_UNIT_FILE="${USER_UNIT_DIR}/${SERVICE_NAME}"

echo "Raspberry Pi Internet Health Check installer"
echo
echo "Project directory: ${PROJECT_DIR}"
echo

if [[ "${PROJECT_DIR}" != "${HOME}/Projects/pi_health_check" ]]; then
    echo "WARNING: this project is normally expected at:"
    echo "  ${HOME}/Projects/pi_health_check"
    echo "The service file uses that path."
    echo
    read -r -p "Continue anyway? [y/N] " answer
    [[ "${answer}" =~ ^[Yy]$ ]] || exit 1
fi

if [[ -f "${ENV_FILE}" ]]; then
    echo "An existing .env was found."
    read -r -p "Replace the existing Healthchecks.io Ping URL? [y/N] " answer

    if [[ "${answer}" =~ ^[Yy]$ ]]; then
        read -r -s -p "Paste the Healthchecks.io Ping URL: " PING_URL
        echo
        [[ -n "${PING_URL}" ]] || {
            echo "Ping URL cannot be empty." >&2
            exit 1
        }

        cat > "${ENV_FILE}" <<EOF
# Secret Healthchecks.io Ping URL.
# Do not commit this file.
HEALTHCHECKS_PING_URL=${PING_URL}
HEARTBEAT_INTERVAL_SECONDS=60
HEARTBEAT_TIMEOUT_SECONDS=20
EOF
        chmod 600 "${ENV_FILE}"
    else
        echo "Keeping existing .env."
    fi
else
    read -r -s -p "Paste the Healthchecks.io Ping URL: " PING_URL
    echo
    [[ -n "${PING_URL}" ]] || {
        echo "Ping URL cannot be empty." >&2
        exit 1
    }

    cat > "${ENV_FILE}" <<EOF
# Secret Healthchecks.io Ping URL.
# Do not commit this file.
HEALTHCHECKS_PING_URL=${PING_URL}
HEARTBEAT_INTERVAL_SECONDS=60
HEARTBEAT_TIMEOUT_SECONDS=20
EOF
    chmod 600 "${ENV_FILE}"
fi

chmod +x "${PROJECT_DIR}/heartbeat.sh"

mkdir -p "${USER_UNIT_DIR}"
cp "${PROJECT_DIR}/pi-health-check.service" "${USER_UNIT_FILE}"

systemctl --user daemon-reload
systemctl --user enable --now "${SERVICE_NAME}"

echo
echo "Installed and started ${SERVICE_NAME}."
echo
systemctl --user --no-pager --full status "${SERVICE_NAME}"
echo
echo "If this service must start after reboot without logging in, run:"
echo
echo "  sudo loginctl enable-linger ${USER}"
echo
echo "Logs:"
echo "  journalctl --user -u ${SERVICE_NAME} -n 100 -f"
