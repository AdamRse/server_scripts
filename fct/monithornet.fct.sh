# Affiche l'aide, commande -h
# return string|exit
usage(){
    [[ -z $COMMAND_NAME ]] && eout "usage() : La variable globale COMMAND_NAME doit être initialisée"
    echo "Ce script est dédié à l'enregistrement statistique de l'état du réseau en permanence. Seul les dysfonctionnements du réseau sont enregistrés"
    echo "${COMMAND_NAME} [OPTIONS]"
    echo "Liste des options :"
    echo "      -h                  affiche cette aide"
    echo "          --debug         active les logs de débugage"
}

# Initialise et vérifie les variables globales
# return empty|exit
set_check_globals(){
    local fct_name="${FUNCNAME[0]}()"
    debug_ "Vérification des variables globales"
    check_vars_exist "COMMAND_NAME PING_SERV1 PING_SERV2 LEVEL_1_MS LEVEL_2_MS LEVEL_3_MS"

    [[ -n $NWD_DB_ADDR ]] && [[ -z $NWD_DB_USER ]] && eout "Spécifiez un utilisateur mysql dans NWD_DB_USER (.env) pour une connexion distante (NWD_DB_ADDR). Pour une connexion locale, laissez NWD_DB_ADDR vide dans le .env"

    lout "Vérification de la disponibilité des serveurs de test"
    ! check_ping $PING_SERV1 && eout "Le serveur de test primaire ${PING_SERV1} ne ping pas"
    ! check_ping $PING_SERV2 && eout "Le serveur de test secondaire ${PING_SERV2} ne ping pas"
    [[ -n $PING_SERV3 ]] && ! check_ping $PING_SERV3 && eout "Le serveur de test tertiaire ${PING_SERV3} ne ping pas"
}

# Vérifie si les commandes sont disponibles
# return empty|exit
check_packages(){
    ! command -v mysql &> /dev/null && eout "Mysql n'est pas installé, impossible d'accéder à la commande 'mysql'. Veuillez installer mysql."
}

# Vérifie si la connexion à la base de données s'effectue bien
# return true|exit
check_connect_db(){
    local table="incident"
    local connect_db
    if [[ -z $NWD_DB_ADDR ]]; then
        DB_SOCKET_CONNECT=true
        connect_db="$(mysql "${NWD_DB_NAME}" -e "DESCRIBE ${table};")"
    else
        DB_SOCKET_CONNECT=false
        connect_db="$(mysql -h "${NWD_DB_ADDR}" -u "${NWD_DB_USER}" -p"${NWD_DB_PASSWD}" "${NWD_DB_NAME}" -e "DESCRIBE ${table};")"
    fi
    if [[ $? = 0 ]]; then
        debug_ "✅ La table ${table} est accessible."
        return 0
    else
        debug_ "Mysql renvoie une erreur : ${connect_db}"
        eout "La base de données n'existe pas ou n'est pas accessible avec les variables du .env"
    fi
}

# Vérifie si le ping d'une ip/nom de domaine est possible
# $1    : target    : adresse IP ou nom de domaine
# return bool
check_ping() {
    local target="${1}"
    check_vars_exist "target"
    local nb_packet=1
    local time_out_sec=2

    if ping -c $nb_packet -W $time_out_sec "${target}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# return integer|empty
send_ping(){
    LAST_PING_TEXT="$(ping -c 1 -W $PING_TIMEOUT_SEC -s $PING_BYTE_SIZE "${1}")"
    LAST_PING_MS="$(awk -F'[= ]' '/time=/{printf "%.0f", $(NF-1)}' <<< ${LAST_PING_TEXT})"
}

# Requête mysql pour ajouter un incident à la base de données
# $1    : level_id      : int       : Niveu de l'incident (id de la table level)
# $2    : ping_ms       : int       : Durée du ping
# $3    : full_answer   : text<511  : Message complet de la commande ping
# return bool
db_insert_into_incident(){
    local level_id=${1}
    local ping_ms=${2}
    local full_answer="${3//\'/\\\'}"

    if [[ $DB_SOCKET_CONNECT = true ]]; then
        mysql "${NWD_DB_NAME}" -e "INSERT INTO incident (level_id, ping_ms, full_answer) VALUES (${level_id}, ${ping_ms}, '${full_answer}');" > /dev/null
    else
        mysql -h "${NWD_DB_ADDR}" -u "${NWD_DB_USER}" -p"${NWD_DB_PASSWD}" "${NWD_DB_NAME}" -e "INSERT INTO incident (level_id, ping_ms, full_answer) VALUES (${level_id}, ${ping_ms}, '${full_answer}');" > /dev/null
    fi
}
