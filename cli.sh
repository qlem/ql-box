#!/bin/sh

API_URI="http://localhost:3000"
USER="qlem"
PUB_KEY="/home/qlem/.ssh/ql_box_pub.pem" # should be the server public key for encryption
PVT_KEY="/home/qlem/.ssh/pws_rsa" # should be the user private key for decryption

function display_menu() {
    echo "Menu:
  get     Fetch one/all accounts
  post    Add one/many accounts"
}

function encrypt() {
    iv=$(openssl rand -hex 16)
    key=$(openssl rand -hex 16)
    enc=$(echo -n $1 | openssl enc -aes-128-cbc -e -a -A -salt -iv $iv -K $key)
    ekey=$(echo -n $key | openssl rsautl -encrypt -oaep -pubin -inkey $PUB_KEY | base64 -w 0)
    eiv=$(echo -n $iv | base64 -w 0)
    echo -n "$eiv:$ekey:$enc"
}

function decrypt() {
    reg=^[A-Za-z0-9+/]+={0,2}:[A-Za-z0-9+/]+={0,2}:[A-Za-z0-9+/]+={0,2}$
    if [[ $1 =~ $reg ]]; then
        IFS=':' read -ra enc <<< "$1"
        key=$(echo -n ${enc[1]} | base64 --decode | openssl rsautl -decrypt -oaep -inkey $PVT_KEY | od -t x1 -An | tr -d ' ')
        iv=$(echo -n ${enc[0]} | base64 --decode | od -t x1 -An | tr -d ' ')
        data=$(echo -n ${enc[2]} | openssl enc -aes-128-cbc -d -a -A -iv $iv -K $key)
        echo $data
    else
        echo $1
    fi
}

function post() {
    echo "One account or many? [one/many]"
    echo -n "post > "
    read in
    if [[ $in == "one" ]]; then
        echo "New account: [name;username;email;password]"
        echo -n "post > "
        read in
        IFS=';' read -ra acc <<< "$in"
        if [[ ${#acc[@]} -ne 4 ]]; then
            echo "Wrong input!"
            return 1
        elif [[ -z ${acc[1]} ]] && [[ -z ${acc[2]} ]]; then
            echo "Username and email cannot both be null!"
            return 1
        fi
        json="{\"data\":{\"name\":\"${acc[0]}\",\"username\":\"${acc[1]}\",\"email\":\"${acc[2]}\",\"password\":\"${acc[3]}\"}}"
        data=$(encrypt "${json}")
        res=$(curl -sS -u $USER -X POST $API_URI"/account" -d $data --raw)
        echo $(decrypt $res)
    elif [[ $in == "many" ]]; then
        echo "JSON file path? [/path/to/file.json]"
        echo -n "post > "
        read file
        if [[ ! -f $file ]]; then
            echo "No such file or directory"
            return 1
        elif jq -e . >/dev/null 2>&1 <<< $(cat $file); then
            json=$(cat $file | jq -c .)
            data=$(encrypt "${json}")
            res=$(curl -sS -u $USER -X POST $API_URI"/account/bulk" -d $data --raw)
            echo $(decrypt $res)
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
    read in
    if [[ $in == "all" ]]; then
        res=$(curl -sS -u $USER -X GET $API_URI"/account/all" --raw)
        echo $(decrypt $res)
    elif [[ $in == "one" ]]; then
        echo "Account name?"
        echo -n "get > "
        read name
        if [[ -n $name ]]; then
            res=$(curl -sS -u $USER -X GET $API_URI"/account?name=${name}" --raw)
            echo $(decrypt $res)
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
    read in
    if [[ $in == "q" ]]; then
        exit 0
    elif [[ $in == "m" ]]; then
        display_menu
    elif [[ $in == "get" ]]; then
        get
    elif [[ $in == "post" ]]; then
        post
    else
        echo "Unknown command"
    fi
done
