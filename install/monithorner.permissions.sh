#!/bin/bash

MAIN_SCRIPT_PATH="$(readlink -f "${0}")"
INSTALL_SERVICE_DIR="$(dirname "${MAIN_SCRIPT_PATH}")"
ROOT_DIR="$(dirname "${INSTALL_SERVICE_DIR}")"

source "${ROOT_DIR}/fct/common/terminal-tools.sh" || exit 1
source "${ROOT_DIR}/fct/common/common-tools.sh" || exit 1

service_name="monithornet.service"

lout "Ajout du groupe monithornet au script"
sudo chown :monithornet "${ROOT_DIR}/monithornet.sh"

lout "Ajout des droits de lecture et d'execution"
sudo chmod 750 "${ROOT_DIR}/monithornet.sh"

lout "redémarrage du service"
sudo systemctl restart "${service_name}"
