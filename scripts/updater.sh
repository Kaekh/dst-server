#!/bin/bash

set -e

DIR="/opt/dst"
BUILDVERSION=""
RESTARTSERVER=false

#Check build version
function getBuildVersion {

    local response
    local status
    local newBuildVersion
    local newBuildTime

    response=$(curl https://api.steamcmd.net/v1/info/343050)
    status=$(echo "$response" | jq -r '.status')
    newBuildVersion=$(echo "$response" | jq -r '.data."343050".depots.branches.public.buildid')
    newBuildTime=$(echo "$response" | jq -r '.data."343050".depots.branches.public.timeupdated')

    echo "$newBuildVersion"
    echo "$newBuildTime"
    echo "$status"

    if [[ "$status" == "success" ]] && [[ -n "$newBuildVersion" ]] && [[ -n "$newBuildTime" ]] ; then
        BUILDVERSION="$newBuildVersion:$newBuildTime"
    else
        echo "TODO: ERROR"
    fi

}

#Compare current version with last avaible version
function checkBuildVersion {

    local info
    local currentBuildVersion
    local currentTimestamp
    local newBuildVersion
    local newTimestamp

    if [[ -f "$DIR/build.info" ]]; then
		info=$(head -1 "$DIR"/build.info)
		currentBuildVersion=$(echo "$info" | cut -d':' -f1)
		currentTimestamp=$(echo "$info" | cut -d':' -f2)
	else
		currentBuildVersion=0
		currentTimestamp=0
	fi

    if [[ -n "$BUILDVERSION" ]]; then
		newBuildVersion=$(echo "$BUILDVERSION" | cut -d':' -f1)
		newTimestamp=$(echo "$BUILDVERSION" | cut -d':' -f2)

		#Check if version or date changed
		if [[ "$currentBuildVersion" -ne "$newBuildVersion" ]] || [[ "$currentTimestamp" -lt "$newTimestamp" ]]; then
			RESTARTSERVER=true
		fi
	fi
}

function restartServer {

    local numPlayers
    #check if there are players connected

}

getBuildVersion
checkBuildVersion

if [[ $RESTARTSERVER = true ]]; then
    restartServer
fi

exit 0