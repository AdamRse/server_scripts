#!/bin/bash

# -- VARIABLES --
MAIN_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "${MAIN_SCRIPT_PATH}")"

DEBUG_MODE=false
COMMAND_NAME="./${MAIN_SCRIPT_PATH}"
DB_SOCKET_CONNECT=true

source "${ROOT_DIR}/fct/common/terminal-tools.sh" || exit 1
source "${ROOT_DIR}/fct/common/common-tools.sh" || exit 1
source "${ROOT_DIR}/fct/monithornet.fct.sh"
source "${ROOT_DIR}/.env" || wout "Aucun .env détecté à la racine, les variables seront appliquées par défaut. Pour personnaliser, plaez un .env à la racine sur le modèle de .env.example"

source "${ROOT_DIR}/src/opt-parser/monithornet.parser.sh" || exit 1

# -- CHECKS --
check_packages
set_check_globals
check_connect_db

[[ $PING_BYTE_SIZE =~ ^[0-9]{1,3}$ && $PING_BYTE_SIZE -gt 15 && $PING_BYTE_SIZE -lt 256 ]] || eout "La variable PING_BYTE_SIZE doit être un entier entre 16 et 255 (taille du ping en octet)"
[[ $PING_TIMEOUT_SEC -gt 0 && $PING_TIMEOUT_SEC -lt 11 ]] || eout "La variable PING_TIMEOUT_SEC doit être un entier entre 1 et 10 (délai d'attente en secondes de la réponse ping)"
[[ $LOOP_TIME_SEC -gt 0 && $LOOP_TIME_SEC -lt 601 ]] || eout "La variable LOOP_TIME_SEC doit être un entier entre 1 et 600 (temps d'attente en seconde entre 2 ping)"

if [[ $DB_SOCKET_CONNECT =true ]]; then
    lout "Connexion à la base de données en mode socket"
else
    lout "Connexion à la base de données en mode login"
fi
lout "Taille du ping : ${PING_BYTE_SIZE} octets"
lout "Timeout du ping : ${PING_TIMEOUT_SEC}s"
lout "Durée entre 2 ping : ${LOOP_TIME_SEC}s"

# -- MAIN --
count=1
double_check=false
while true; do
    debug_ "boucle ${count}"

    answer1_ms=$(send_ping "${PING_SERV1}")
    if [[ -z $answer1_ms ]] || [[ $(echo "${answer1_ms} > ${LEVEL_1_MS}" | bc) = 1 ]]; then
        answer2_ms=$(send_ping "${PING_SERV2}")
        if [[ -z $answer2_ms ]] || [[ $(echo "${answer2_ms} > ${LEVEL_1_MS}" | bc) = 1 ]]; then
            # problème confirmé, gravité à déterminer à partir de answer1
            if [[ -z $answer1_ms ]]; then
                MONITOR_LEVEL_ID=4
                MONITOR_PING_MS=$answer1_ms
            elif [[ $(echo "${answer1_ms} < ${LEVEL_2_MS}" | bc) = 1  ]]; then
                MONITOR_LEVEL_ID=1
                MONITOR_PING_MS=$answer1_ms
            elif [[ $(echo "${answer1_ms} < ${LEVEL_3_MS}" | bc) = 1  ]]; then
                MONITOR_LEVEL_ID=2
                MONITOR_PING_MS=$answer1_ms
            else
                MONITOR_LEVEL_ID=3
                MONITOR_PING_MS=$answer1_ms
            fi
            lout "Ping : ${MONITOR_PING_MS}ms\nNiveau : ${MONITOR_LEVEL_ID}"
            db_insert_into_incident ${MONITOR_LEVEL_ID} ${MONITOR_PING_MS}
        fi
    fi

    ((count++))
    sleep $LOOP_TIME_SEC
done
