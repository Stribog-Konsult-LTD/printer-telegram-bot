#!/bin/bash

BASEDIR=$( readlink -f $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) )
pushd $BASEDIR

# Set your configuration file
CONFIG_FILE_NAME="${BASEDIR}/config.ini"

source "./lib-t-bot.sh"

# Generate config file if not exists
[ -z "$(crudini --get "$CONFIG_FILE_NAME" general lastKnownMessageId)" ] \
    && $(crudini --set "$CONFIG_FILE_NAME" general lastKnownMessageId 1)

# Set your download directory
DOWNLOAD_DIR="${BASEDIR}/downloads"
# Make download dir if not exists
mkdir -p "$DOWNLOAD_DIR"

PRINT_MASTER=$(getConfigItem "general" "master" )
if [ -z "$PRINT_MASTER" ] ; then
    printred "Please add master chat id in $CONFIG_FILE_NAME [general]"
    setConfigItem "general" "master" "Master chat id here"
fi

processFile(){
    local file_name=$1
    local file_id=$2
    local mime_type=$3
    local caption=$4
    printgreen "processFile file_name:$file_name, caption: $caption, file_id: $file_id, mime_type: $mime_type"
    local fileInfo=$($TELEGRAM_CURL \
    -X GET \
    ${T_API}/getFile"?file_id=${file_id}" )
    if [ "$(getJsonValue "$fileInfo" ".ok" )" == true ] ; then
        local file_path="$(getJsonValue "$fileInfo" ".result.file_path")"
        download_file_name="$DOWNLOAD_DIR/$file_name"
        wget ${T_FILE}/$file_path -O "$download_file_name"
        if [ "${mime_type}" == "application/pdf" ] ; then
            lp_output=$(lp  "$download_file_name")
            echo "lp_output: $lp_output"
        fi
    else
        printred "Error fileInfo"
        echo "$fileInfo" | jq
    fi


}

# processText(){
# }
#
# processCommand(){
# }

processMessage(){
    local jsonResult="$1"
    if [ "$(getJsonValue "$jsonResult" ".ok" )" == "true" ] ; then
        echo $jsonResult | jq
        local update_id="$(getJsonValue "$jsonResult" '.result[0].update_id' )"
        if [ "$(isNumber $update_id)" == 'yes' ] ; then
            setLastKnown $( expr $update_id + 1)
        else
            printred "Unknown  update_id:  $update_id"
            return
        fi
        local chatId="$(getJsonValue "$jsonResult" '.result[0].message.chat.id')"
        if [ "$chatId" == "$PRINT_MASTER" ] ; then
            local file_name="$(getJsonValue "$jsonResult" '.result[0].message.document.file_name' )"
            if [  -n "$file_name" ] ; then
                printgreen "It is file: $file_name"
                local caption="$(getJsonValue "$jsonResult" '.result[0].message.caption' )"
                echo "File name is: $file_name, caption: $caption"
                processFile \
                    "$file_name"  \
                    "$(getJsonValue "$jsonResult" '.result[0].message.document.file_id' )" \
                    "$(getJsonValue "$jsonResult" '.result[0].message.document.mime_type' )" \
                    "$caption"
            else
                local text="$(getJsonValue "$jsonResult" '.result[0].message.text' )"
                echo "text: $text"
                echo "$jsonResult" | jq
            fi
        else
            printred "Wrong chat id: $chatId, I wait: $PRINT_MASTER"
            sendTextMessage "Your chat ID is: $chatId, set it in configuration file as master" "$chatId"
        fi
    else
       echo -n "."
    fi
}


while [ true ]
do
    jsonResult=$(getUpdates)
    processMessage "$jsonResult"
done


popd
