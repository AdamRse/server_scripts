#!/bin/bash

# -- VARIABLES
MAIN_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "${MAIN_SCRIPT_PATH}")"

DEBUG_MODE=false
COMMAND_NAME="./${MAIN_SCRIPT_PATH}"

source "${ROOT_DIR}/fct/common/terminal-tools.sh" || exit 1
source "${ROOT_DIR}/fct/common/common-tools.sh" || exit 1
source "${ROOT_DIR}/fct/monithornet.fct.sh"
source "${ROOT_DIR}/.env" || wout "Aucun .env détecté à la racine, les variables seront appliquées par défaut. Pour personnaliser, plaez un .env à la racine sur le modèle de .env.example"

source "${ROOT_DIR}/src/opt-parser/monithornet.parser.sh" || exit 1


# -- MAIN
check_packages
set_check_globals
check_connect_db


echo "ok"
