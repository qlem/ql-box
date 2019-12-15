#!/bin/sh

IV=$(openssl rand -hex 16)
KEY=$(openssl rand -hex 16)
DATA=$(cat /home/qlem/Downloads/accounts.json | jq -c .)
ENC=$(echo -n $DATA | openssl enc -aes-128-cbc -e -a -A -salt -iv $IV -K $KEY)
echo $ENC
DEC=$(echo $ENC | openssl enc -aes-128-cbc -d -a -A -iv $IV -K $KEY)
echo $DEC
