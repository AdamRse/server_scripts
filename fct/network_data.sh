usage() {
    [[ -z $COMMAND_NAME ]] && eout "usage() : La variable globale COMMAND_NAME doit être initialisée"
    echo "Ce script est dédié à l'enregistrement statistique de l'état du réseau en permanence. Seul les dysfonctionnements du réseau sont enregistrés"
    echo "${COMMAND_NAME} [OPTIONS]"
    echo "Liste des options :"
    echo "      -h                  affiche cette aide"
    echo "          --debug         active les logs de débugage"
}

# Initialise et vérifie les variables globales
# return empty|exit
check_globals(){

}
set_check_globals(){
    local fct_name="${FUNCNAME[0]}()"
    debug_ "Vérification des variables globales"
    [[ -z $COMMAND_NAME  ]] && eout "${fct_name} : La variable globale COMMAND_NAME doit être initialisée"
    [[ -z $NWD_DB_ADDR ]]  && eout "${fct_name} : La variable globale NWD_DB_ADDR doit être initialisée dans le .env"
    [[ -z $NWD_DB_ADDR ]]  && eout "${fct_name} : La variable globale NWD_DB_ADDR doit être initialisée dans le .env"
}
