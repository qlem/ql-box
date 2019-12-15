#!/bin/sh

API_URI="http://localhost:3000"
USER=qlem

function display_menu() {
    echo "Menu:
  get     Fetch one/all accounts
  post    Add one/many accounts"
}

function encrypt() {
    IV=$(openssl rand -hex 16)
    KEY=$(openssl rand -hex 16)
    ENC=$(echo -n $1 | openssl enc -aes-128-cbc -e -a -A -salt -iv $IV -K $KEY)
    EKEY=$(echo -n $KEY | openssl rsautl -encrypt -pubin -inkey ./.pem/public.pem | base64)
    EIV=$(echo -n $IV | base64)
    echo -n "$EIV:$EKEY:$ENC"
    # DEC=$(echo $ENC | openssl enc -aes-128-cbc -d -a -A -iv $IV -K $KEY)
    # echo -n $DEC
}

function encrypt_bak() {
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
        echo "JSON file path? [/path/to/file.json]"
        echo -n "post > "
        read FILE
        if [[ ! -f $FILE ]]; then
            echo "No such file or directory"
            return 1
        elif jq -e . >/dev/null 2>&1 <<< $(cat $FILE); then
            JSON=$(cat $FILE | jq -c .)
            
            IV=$(openssl rand -hex 16)
            KEY=$(openssl rand -hex 16)
            ENC=$(echo -n $JSON | openssl enc -aes-128-cbc -e -a -A -salt -iv $IV -K $KEY)
            EKEY=$(echo -n $KEY | openssl rsautl -encrypt -pubin -inkey ./.pem/public.pem | base64)
            EIV=$(echo -n $IV | base64)
            DATA="$EIV:$EKEY:$ENC"
            # $(encrypt $json)
            RES=$(curl -sS -u $USER -X POST $API_URI"/account/bulk" -d "$DATA")
            # echo $(decrypt $RES) 
        else
            echo "JSON file is not valid!"
        fi
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
