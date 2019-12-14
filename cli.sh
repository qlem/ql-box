#!/bin/sh

API_URI="http://localhost:3000"
USER=qlem

function display_menu() {
    echo "Menu:
get     Fetch one/all accounts
post    Add one/many accounts"
}

function encrypt() {
    local data=$(echo -n $1 | openssl rsautl -encrypt -pubin -inkey ./.pem/public.pem | base64)
    echo -n $data
}

function decrypt() {
    local data=$(echo $1 | base64 --decode | openssl rsautl -decrypt -inkey ~/.ssh/pws_rsa)
    echo $data
}

function post() {
    echo "One account or many? [one/many]"
    echo -n "post > "
    read INP
    if [[ $INP == "one" ]]; then
        echo "New account: [name;username;email;password]"
        echo -n "post > "
        read INP
        IFS=';' read -ra ARR <<< "$INP"
        if [[ ${#ARR[@]} -ne 4 ]]; then
            echo "Wrong input!"
            return 1
        elif [[ -z ${ARR[1]} ]] && [[ -z ${ARR[2]} ]]; then
            echo "Username and email cannot both be null!"
            return 1
        fi
        JSON="{\"data\":{\"name\":\"${ARR[0]}\",\"username\":\"${ARR[1]}\",\"email\":\"${ARR[2]}\",\"password\":\"${ARR[3]}\"}}"
        RES=$(curl -sS -u $USER -X POST $API_URI"/account" -d "$(encrypt $JSON)")
        echo $(decrypt $RES)
    elif [[ $INP == "many" ]]; then
        echo "many"
    else
        echo "Unknown command"
    fi
}

function get() {
    echo "One account or list all accounts names? [one/all]"
    echo -n "get > "
    read ING
    if [[ $ING == "all" ]]; then
        RES=$(curl -sS -u $USER -X GET $API_URI"/account/all")
        echo $(decrypt $RES)
    elif [[ $ING == "one" ]]; then
        echo "Account name?"
        echo -n "get > "
        read NAME
        if [[ -n $NAME ]]; then
            RES=$(curl -sS -u $USER -X GET $API_URI"/account?name=${NAME}")
            echo $(decrypt $RES)
        else
            echo "Account name cannot be null!"
        fi
    else
        echo "Unknown command"
    fi
}

echo "Welcome to ql-box"
echo "Type 'm' to display menu or 'q' to quit"
echo
while true; do
    echo -n "> "
    read IN
    if [[ $IN == "q" ]]; then
        exit 0
    elif [[ $IN == "m" ]]; then
        display_menu
    elif [[ $IN == "get" ]]; then
        get
    elif [[ $IN == "post" ]]; then
        post
    else
        echo "Unknown command"
    fi
done
