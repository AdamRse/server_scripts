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
    check_vars_exist "COMMAND_NAME NWD_DB_ADDR NWD_DB_NAME PING_SERV1 PING_SERV2"

    lout "Vérification de la disponnibilité des serveurs de test"
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
    connect_db="$(mysql -h "${NWD_DB_ADDR}" -u "${NWD_DB_USER}" -p"${NWD_DB_PASSWD}" "${NWD_DB_NAME}" -e "DESCRIBE ${table};")"
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
