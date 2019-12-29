#!/bin/sh

if [[ "$#" -gt 4 ]]; then
    echo 'USAGE: script.sh <username> <api uri> <api public key> <user private key>'
    exit 1
fi 

for arg in "$@"; do
    if [[ "$arg" == '-h' ]]; then
        echo 'USAGE: script.sh <username> <api uri> <api public key> <user private key>'
        exit 0
    fi
done

API_URI='http://localhost:3000'
USER="$USER"
PUB_KEY="/home/${USER}/.ssh/ql-box/api_pub.pem"
PVT_KEY="/home/${USER}/.ssh/ql-box/user_pvt.pem"

[[ "$1" ]] && USER="$1"
[[ "$2" ]] && API_URI="$2"
[[ "$3" ]] && PUB_KEY="$3"
[[ "$4" ]] && PVT_KEY="$4"

[[ ! -f "$PUB_KEY" ]] && echo 'Public key file does not exist!' && exit 1
[[ ! -f "$PVT_KEY" ]] && echo 'Private key file does not exist!' && exit 1

BLUE='\e[0;34m'
BBLUE='\e[1;34m'
RED='\e[0;31m'
BRED='\e[1;31m'
YLLW='\e[0;33m'
BWHITE='\e[1;37m'
NC='\e[0m'

function encrypt() {
    local iv=$(openssl rand -hex 16)
    local key=$(openssl rand -hex 16)
    local enc=$(echo -n "$1" | openssl enc -aes-128-cbc -e -a -A -salt -iv "$iv" -K "$key")
    local ekey=$(echo -n "$key" | openssl rsautl -encrypt -oaep -pubin -inkey "$PUB_KEY" | base64 -w 0)
    local eiv=$(echo -n "$iv" | base64 -w 0)
    DATA="$eiv:$ekey:$enc"
}

function decrypt() {
    reg=^[A-Za-z0-9+/]+={0,2}:[A-Za-z0-9+/]+={0,2}:[A-Za-z0-9+/]+={0,2}$
    if [[ "$1" =~ $reg ]]; then
        IFS=':' read -ra enc <<< "$1"
        local key=$(echo -n "${enc[1]}" | base64 --decode | openssl rsautl -decrypt -oaep -inkey "$PVT_KEY" | od -t x1 -An | tr -d ' ')
        local iv=$(echo -n "${enc[0]}" | base64 --decode | od -t x1 -An | tr -d ' ')
        local data=$(echo -n "${enc[2]}" | openssl enc -aes-128-cbc -d -a -A -iv "$iv" -K "$key")
        DATA="$data"
    else
        DATA="$1"
    fi
}

function update() {
    echo -e "${BLUE}Update account: [name;username;email;password]${NC}"
    echo -n 'update > '
    read in
    IFS=';' read -ra acc <<< "$in"
    if [[ "${#acc[@]}" -ne 4 ]]; then
        echo -e "${RED}Wrong input!${NC}"
    elif [[ -z "${acc[1]}" ]] && [[ -z "${acc[2]}" ]]; then
        echo -e "${RED}Username and email cannot both be null!${NC}"
    else
        local json="{\"data\":{\"name\":\"${acc[0]}\",\"username\":\"${acc[1]}\",\"email\":\"${acc[2]}\",\"password\":\"${acc[3]}\"}}"
        encrypt "$json"
        local res=$(curl -sS -u "$USER" -X POST "${API_URI}/account/update" -d "$DATA" --raw)
        if [[ "$?" -ne 0 ]]; then
            echo -e "${BRED}An error has occurred!${NC}"
            return "$?"
        fi
        decrypt "$res"
        echo "$DATA"
    fi
}

function delete() {
    echo -e "${BLUE}Account name?${NC}"
    echo -n 'delete > '
    read name
    if [[ -n "$name" ]]; then
        local param=$(echo -n "${name//[[:blank:]]/%20}")
        local res=$(curl -sS -u "$USER" -X DELETE "${API_URI}/account?name=${param}" --raw)
        if [[ "$?" -ne 0 ]]; then
            echo -e "${BRED}An error has occurred!${NC}"
            return "$?"
        fi
        decrypt "$res"
        echo "$DATA"
    else
        echo -e "${RED}Account name expected!${NC}"
    fi
}

function add_one() {
    echo -e "${BLUE}New account: [name;username;email;password]${NC}"
    echo -n 'add > '
    read in
    IFS=';' read -ra acc <<< "$in"
    if [[ "${#acc[@]}" -ne 4 ]]; then
        echo -e "${RED}Wrong input!${NC}"
    elif [[ -z "${acc[1]}" ]] && [[ -z "${acc[2]}" ]]; then
        echo -e "${RED}Username and email cannot both be null!${NC}"
    else
        local json="{\"data\":{\"name\":\"${acc[0]}\",\"username\":\"${acc[1]}\",\"email\":\"${acc[2]}\",\"password\":\"${acc[3]}\"}}"
        encrypt "$json"
        local res=$(curl -sS -u "$USER" -X POST "${API_URI}/account" -d "$DATA" --raw)
        if [[ "$?" -ne 0 ]]; then
            echo -e "${BRED}An error has occurred!${NC}"
            return "$?"
        fi
        decrypt "$res"
        echo "$DATA"
    fi
}

function add_many() {
    echo -e "${BLUE}JSON file path? [/path/to/file.json]${NC}"
    echo -n 'add > '
    read file
    if [[ ! -n "$file" ]]; then
        echo -e "${RED}File expected!${NC}"
    elif [[ ! -e "$file" ]]; then
        echo -e "${RED}No such file or directory!${NC}"
    elif [[ ! -f "$file" ]]; then
        echo -e "${RED}File expected!${NC}"
    elif jq -e . > /dev/null 2>&1 <<< $(cat "$file"); then
        local json=$(cat "$file" | jq -c .)
        encrypt "$json"
        local res=$(curl -sS -u "$USER" -X POST "${API_URI}/account/bulk" -d "$DATA" --raw)
        if [[ "$?" -ne 0 ]]; then
            echo -e "${BRED}An error has occurred!${NC}"
            return "$?"
        fi
        decrypt "$res"
        echo "$DATA"
    else
        echo -e "${RED}JSON file is not valid!${NC}"
    fi
}

function add() {
    echo -e "${BLUE}One account or many? [one/many]${NC}"
    echo -n 'add > '
    read in
    if [[ "$in" == 'one' ]]; then
        add_one
    elif [[ "$in" == 'many' ]]; then
        add_many
    elif [[ ! -n "$in" ]]; then
        echo -e "${YLLW}Command expected!${NC}"
    else
        echo -e "${YLLW}Unknown command!${NC}"
    fi
}

function get_one() {
    echo -e "${BLUE}Account name?${NC}"
    echo -n 'get > '
    read name
    if [[ -n "$name" ]]; then
        local param=$(echo -n "${name//[[:blank:]]/%20}")
        local res=$(curl -sS -u "$USER" -X GET "${API_URI}/account?name=${param}" --raw)
        if [[ "$?" -ne 0 ]]; then
            echo -e "${BRED}An error has occurred!${NC}"
            return "$?"
        fi
        decrypt "$res"
        echo "$DATA"
    else
        echo -e "${RED}Account name expected!${NC}"
    fi
}

function get() {
    echo -e "${BLUE}One account or list all accounts names? [one/all]${NC}"
    echo -n 'get > '
    read in
    if [[ "$in" == 'all' ]]; then
        local res=$(curl -sS -u "$USER" -X GET "${API_URI}/account/all" --raw)
        if [[ "$?" -ne 0 ]]; then
            echo -e "${BRED}An error has occurred!${NC}"
            return "$?"
        fi
        decrypt "$res"
        echo "$DATA"
    elif [[ "$in" == 'one' ]]; then
        get_one
    elif [[ ! -n "$in" ]]; then
        echo -e "${YLLW}Command expected!${NC}"
    else
        echo -e "${YLLW}Unknown command!${NC}"
    fi
}

function display_help() {
    echo 'Commands:
  get      Fetch one/all accounts
  add      Add one/many accounts
  update   Update an existing account
  delete   Delete an existing account
  help     Display this help
  exit     Exit the program'
}

echo -e "${BBLUE}Welcome to ql-box${NC}"
echo 'Enter a command.. [help/exit]'
echo
while true; do
    echo -n '> '
    read in
    if [[ "$in" == 'exit' ]]; then
        echo -e "${BWHITE}Bye..${NC}"
        exit 0
    elif [[ "$in" == 'help' ]]; then
        display_help
    elif [[ "$in" == 'get' ]]; then
        get
    elif [[ "$in" == 'add' ]]; then
        add
    elif [[ "$in" == 'update' ]]; then
        update
    elif [[ "$in" == 'delete' ]]; then
        delete
    elif [[ -n "$in" ]]; then
        echo -e "${YLLW}Unknown command!${NC}"
    fi
done
