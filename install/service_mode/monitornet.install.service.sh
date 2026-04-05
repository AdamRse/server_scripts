#!/bin/bash
# Installer en tant que service.
# Peut être utilisé pour actualier le template, mais i faudra redémarrer le service

MAIN_SCRIPT_PATH="$(readlink -f "${0}")"
INSTALL_SERVICE_DIR="$(dirname "${MAIN_SCRIPT_PATH}")"
ROOT_DIR="${MAIN_SCRIPT_PATH%/*/*/*}"

source "${ROOT_DIR}/fct/common/terminal-tools.sh" || exit 1
source "${ROOT_DIR}/fct/common/common-tools.sh" || exit 1

service_name="monithornet.service"
service_path="/etc/systemd/system/${service_name}"
template_service_path="${INSTALL_SERVICE_DIR}/files/monithornet.service"

[[ ! -f $template_service_path ]] && eout "Le template du service est introuvable dans '${template_service_path}'"

lout "Création du service"
sudo cp "${template_service_path}" "${service_path}"||eout "impossible de créer le fichier de service : '${service_path}'"
sudo chmod 644 "${service_path}"

lout "Rechargement du deamon"
sudo systemctl daemon-reload

lout "Activation du service monithornet"
sudo systemctl enable "${service_name}"

lout "Démarrage du service monithornet"
sudo systemctl start "${service_name}"
