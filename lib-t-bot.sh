#!/bin/sh


BASEDIR=$( readlink -f $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) )

printred(){
    RED='\033[06;33m'
    NC='\033[00m' # No Color
    echo -e "\n${RED}${@}${NC} \n"
}

printgreen(){
    GREEN='\033[06;32m'
    NC='\033[00m' # No Color
    echo -e  "\n${GREEN}${@}${NC} \n"
}

printblue(){
    GREEN='\033[01;34m'
    NC='\033[00m' # No Color
    echo -e  "\n${GREEN}${@}${NC} \n"
}



getConfigItem() {
    local section="$1"
    local key="$2"
    echo $(crudini --get  "${CONFIG_FILE_NAME}" "${section}" "${key}" )
}

setConfigItem(){
    local section="$1"
    local key="$2"
    local value="$3"
    crudini --set  "${CONFIG_FILE_NAME}" "${section}" "${key}"  "${value}"
}

T_BOT_KEY=$(getConfigItem "general" "botKey" )
if [ -z "$T_BOT_KEY" ] ; then
    printred "Please add botKey in $CONFIG_FILE_NAME [general]"
    setConfigItem "general" "botKey" "Bot key here"
    exit 1
fi

T_API="https://api.telegram.org/bot$T_BOT_KEY"
T_FILE="https://api.telegram.org/file/bot$T_BOT_KEY"
TELEGRAM_CURL="timeout -s KILL 4 curl -k -s --max-time 10 --connect-timeout 3 "


getLastKnown(){
    echo "$(getConfigItem "general" "lastKnownMessageId")"
}

setLastKnown(){
    local lastKnown="$1"
    setConfigItem "general" "lastKnownMessageId" "$lastKnown"
}


getUpdates(){
    local lastKnown=$(getLastKnown)
    local jsonResult=$( 
    $TELEGRAM_CURL \
    -X GET \
    ${T_API}/getUpdates"?limit=1&offset=${lastKnown}&timeout=10" )
    
    echo ${jsonResult}
}

isNumber(){
    local re='^[0-9]+$'
    local number="$1"
    if ! [[ $number =~ $re ]] ; then
        echo "no"
    else
        echo "yes"
    fi
}

getJsonValue(){
    local json=$1
    local key=$2
    value=$(echo "$json" | jq -r "$key // empty")
    echo $value

}

sendTextMessage () {

    local text="$1"
    [ -n "$2" ] && local chat_id=$2 || local chat_id=$PRINT_MASTER

    $TELEGRAM_CURL \
        -X POST \
        ${T_API}/sendMessage \
        -d chat_id=$chat_id \
        -d parse_mode=Markdown \
        --data-urlencode text="$text"


}
