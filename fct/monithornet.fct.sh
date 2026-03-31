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
    check_vars_exist "COMMAND_NAME NWD_DB_ADDR NWD_DB_NAME"
}

check_packages(){
    ! command -v mysql &> /dev/null && eout "Mysql n'est pas installé, impossible d'accéder à la commande 'mysql'. Veuillez installer mysql."
}

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
