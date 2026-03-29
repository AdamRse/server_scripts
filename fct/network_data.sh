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
check_globals() {
    local prev_function="${FUNCNAME[1]:-FUNCNAME[2]}"
    local fct_name
    local vars_to_check=$1
    local missing_count=0

    for var_name in $vars_to_check; do
        if [[ -z "${!var_name}" ]]; then
            eout "La variable globale '$var_name' n'est pas initialisée."
            ((missing_count++))
        fi
    done
}
set_check_globals(){
    local fct_name="${FUNCNAME[0]}()"
    debug_ "Vérification des variables globales"
    [[ -z $COMMAND_NAME ]] && eout "${fct_name} : La variable globale COMMAND_NAME doit être initialisée"
    [[ -z $NWD_DB_ADDR ]]  && eout "${fct_name} : La variable globale NWD_DB_ADDR doit être initialisée dans le .env"
    [[ -z $NWD_DB_ADDR ]]  && eout "${fct_name} : La variable globale NWD_DB_ADDR doit être initialisée dans le .env"
}
