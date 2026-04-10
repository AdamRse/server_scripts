#!/bin/bash

MAIN_SCRIPT_PATH="$(readlink -f "${0}")"
INSTALL_SERVICE_DIR="$(dirname "${MAIN_SCRIPT_PATH}")"
ROOT_DIR="$(dirname "${INSTALL_SERVICE_DIR}")"

sudo chown :monithornet "${ROOT_DIR}/monithornet.sh"
sudo chmod 750 "${ROOT_DIR}/monithornet.sh"
