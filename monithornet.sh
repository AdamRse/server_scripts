#!/bin/bash

# -- VARIABLES --
MAIN_SCRIPT_PATH="$(readlink -f "$0")"
ROOT_DIR="$(dirname "${MAIN_SCRIPT_PATH}")"

DEBUG_MODE=false
COMMAND_NAME="./${MAIN_SCRIPT_PATH}"
DB_SOCKET_CONNECT=true

LAST_PING_TEXT=""
LAST_PING_MS=""

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

if [[ $DB_SOCKET_CONNECT = true ]]; then
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

    answer_1_ms="${LAST_PING_MS:-0}"
    send_ping "${PING_SERV1}"
    if [[ $answer_1_ms = 0 ]] || [[ $(echo "${answer_1_ms} > ${LEVEL_1_MS}" | bc) = 1 ]]; then
        answer_1_txt="${LAST_PING_TEXT}"
        lout "Problème de ping détecté sur serveur primaire : ${PING_SERV1}"
        lout "Ping reçu : ${answer_1_ms}ms"
        debug_ "Message complet : ${answer_1_txt}"
        lout "Ping du serveur secondaire ${PING_SERV2} pour confirmation"

        send_ping "${PING_SERV2}"
        answer_2_ms="${LAST_PING_MS:-0}"
        if [[ $answer_2_ms = 0 ]] || [[ $(echo "${answer_2_ms} > ${LEVEL_1_MS}" | bc) = 1 ]]; then
            # problème confirmé, gravité à déterminer à partir de answer_1_ms
            answer_2_txt="${LAST_PING_TEXT}"

            MONITOR_PING_MS=$answer_1_ms
            MONITOR_PING_FULL_ANSWER="${answer_1_txt}"
            if [[ $answer_1_ms = 0 ]]; then
                MONITOR_LEVEL_ID=4
            elif [[ $(echo "${answer_1_ms} < ${LEVEL_2_MS}" | bc) = 1  ]]; then
                MONITOR_LEVEL_ID=1
            elif [[ $(echo "${answer_1_ms} < ${LEVEL_3_MS}" | bc) = 1  ]]; then
                MONITOR_LEVEL_ID=2
            else
                MONITOR_LEVEL_ID=3
            fi

            lout "Problème détecté sur le serveur secondaire : ${PING_SERV2}"
            lout "Ping reçu : ${answer_2_ms}ms"
            debug_ "Message complet : ${answer_2_txt}"
            lout "------ AJOUT DE L'INCIDENT À LA BASE DE DONNÉES ------ "
            lout "Ajout de ping : ${MONITOR_PING_MS}ms\n\tNiveau : ${MONITOR_LEVEL_ID}"
            db_insert_into_incident ${MONITOR_LEVEL_ID} ${MONITOR_PING_MS} "${MONITOR_PING_FULL_ANSWER}" ||fout "Impossible d'enregistrer l'incident en base de données, la requête est refusée !"
        fi
    fi

    ((count++))
    sleep $LOOP_TIME_SEC
done
