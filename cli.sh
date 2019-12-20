#!/bin/sh

API_URI='http://localhost:3000'
USER='john'

# should be the api public key for encryption
PUB_KEY='/path/to/keys/dir/api.pem'

# should be the user private key for decryption
PVT_KEY='/path/to/keys/dir/private.pem'

# some colors
GREEN='\e[0;32m'
BLUE='\e[0;34m'
BBLUE='\e[1;34m'
RED='\e[0;31m'
BRED='\e[1;31m'
YLLW='\e[0;33m'
NC='\e[0m'

function encrypt() {
    iv=$(openssl rand -hex 16)
    key=$(openssl rand -hex 16)
    enc=$(echo -n "$1" | openssl enc -aes-128-cbc -e -a -A -salt -iv "$iv" -K "$key")
    ekey=$(echo -n "$key" | openssl rsautl -encrypt -oaeps -pubin -inkey "$PUB_KEY" | base64 -w 0)
    eiv=$(echo -n "$iv" | base64 -w 0)
    echo -n "$eiv:$ekey:$enc"
}

function decrypt() {
    reg=^[A-Za-z0-9+/]+={0,2}:[A-Za-z0-9+/]+={0,2}:[A-Za-z0-9+/]+={0,2}$
    if [[ "$1" =~ $reg ]]; then
        IFS=':' read -ra enc <<< "$1"
        key=$(echo -n "${enc[1]}" | base64 --decode | openssl rsautl -decrypt -oaep -inkey "$PVT_KEY" | od -t x1 -An | tr -d ' ')
        iv=$(echo -n "${enc[0]}" | base64 --decode | od -t x1 -An | tr -d ' ')
        data=$(echo -n "${enc[2]}" | openssl enc -aes-128-cbc -d -a -A -iv "$iv" -K "$key")
        echo "$data"
    else
        echo "$1"
    fi
}

function post() {
    echo -e "${GREEN}One account or many? [one/many]${NC}"
    echo -n 'post > '
    read in
    if [[ "$in" == 'one' ]]; then
        echo -e "${GREEN}New account: [name;username;email;password]${NC}"
        echo -n 'post > '
        read in
        IFS=';' read -ra acc <<< "$in"
        if [[ "${#acc[@]}" -ne 4 ]]; then
            echo -e "${RED}Wrong input!${NC}"
            return 1
        elif [[ -z "${acc[1]}" ]] && [[ -z "${acc[2]}" ]]; then
            echo -e "${RED}Username and email cannot both be null!${NC}"
            return 1
        fi
        json="{\"data\":{\"name\":\"${acc[0]}\",\"username\":\"${acc[1]}\",\"email\":\"${acc[2]}\",\"password\":\"${acc[3]}\"}}"
        data=$(encrypt "$json")
        res=$(curl -sS -u "$USER" -X POST "${API_URI}/account" -d "$data" --raw)
        if [[ "$?" -ne 0 ]]; then
            echo -e "${BRED}An error has occurred!${NC}"
            return "$?"
        fi
        echo $(decrypt "$res")
    elif [[ "$in" == 'many' ]]; then
        echo -e "${GREEN}JSON file path? [/path/to/file.json]${NC}"
        echo -n 'post > '
        read file
        if [[ ! -n "$file" ]]; then
            echo -e "${RED}File expected!${NC}"
            return 1
        elif [[ ! -e "$file" ]]; then
            echo -e "${RED}No such file or directory!${NC}"
            return 1
        elif [[ ! -f "$file" ]]; then
            echo -e "${RED}File expected!${NC}"
        elif jq -e . > /dev/null 2>&1 <<< $(cat "$file"); then
            json=$(cat "$file" | jq -c .)
            data=$(encrypt "$json")
            res=$(curl -sS -u "$USER" -X POST "${API_URI}/account/bulk" -d "$data" --raw)
            if [[ "$?" -ne 0 ]]; then
                echo -e "${BRED}An error has occurred!${NC}"
                return "$?"
            fi
            echo $(decrypt "$res")
        else
            echo -e "${RED}JSON file is not valid!${NC}"
        fi
    elif [[ ! -n "$in" ]]; then
        echo -e "${YLLW}Command expected!${NC}"
    else
        echo -e "${YLLW}Unknown command!${NC}"
    fi
}

function get() {
    echo -e "${GREEN}One account or list all accounts names? [one/all]${NC}"
    echo -n 'get > '
    read in
    if [[ "$in" == 'all' ]]; then
        res=$(curl -sS -u "$USER" -X GET "${API_URI}/account/all" --raw)
        if [[ "$?" -ne 0 ]]; then
            echo -e "${BRED}An error has occurred!${NC}"
            return "$?"
        fi
        echo $(decrypt "$res")
    elif [[ "$in" == 'one' ]]; then
        echo -e "${GREEN}Account name?${NC}"
        echo -n 'get > '
        read name
        if [[ -n "$name" ]]; then
            param=$(echo -n "${name//[[:blank:]]/%20}")
            res=$(curl -sS -u "$USER" -X GET "${API_URI}/account?name=${fname}" --raw)
            if [[ "$?" -ne 0 ]]; then
                echo -e "${BRED}An error has occurred!${NC}"
                return "$?"
            fi
            echo $(decrypt "$res")
        else
            echo -e "${RED}Account name cannot be null!${NC}"
        fi
    elif [[ ! -n "$in" ]]; then
        echo -e "${YLLW}Command expected!${NC}"
    else
        echo -e "${YLLW}Unknown command!${NC}"
    fi
}

function display_help() {
    echo 'Commands:
  get     Fetch one/all accounts
  post    Add one/many accounts
  help    Display this help
  exit    Exit the program'
}

echo -e "${BBLUE}Welcome to ql-box${NC}"
echo 'Enter a command.. [help/exit]'
echo
while true; do
    echo -n '> '
    read in
    if [[ "$in" == 'exit' ]]; then
        echo 'Bye'
        exit 0
    elif [[ "$in" == 'help' ]]; then
        display_help
    elif [[ "$in" == 'get' ]]; then
        get
    elif [[ "$in" == 'post' ]]; then
        post
    elif [[ -n "$in" ]]; then
        echo -e "${YLLW}Unknown command!${NC}"
    fi
done
