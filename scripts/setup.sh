#!/bin/bash

set -e

CURRENTUID=$(id -u)
NUMCHECK='^[0-9]+$'
USER="dst"
NAME=${SERVER_NAME:-DSTServer}
DIR="/opt/dst/.klei/DoNotStarveTogether/$NAME"
MODS_FILE="/opt/dst/dedicated_server_mods_setup.lua"

# ==== Log Functions ====
# Info log
function log_info() {
    echo -e "\033[0;36mINFO:\033[0m $1"
}

# Warning log
function log_warn() {
    echo -e "\033[0;33mWARNING:\033[0m $1"
}

# Error log
function log_error() {
    echo -e "\033[0;31mERROR:\033[0m $1"
}


# check if the user and group IDs have been set
if [[ "$CURRENTUID" -ne "0" ]]; then
    log_error "Current user ($CURRENTUID) is not root (0)"
    exit 1
fi

if ! [[ "$PGID" =~ $NUMCHECK ]] ; then
    log_warn "Invalid group id given: $PGID - Container will be created with group id 1000"
    PGID="1000"
elif [[ "$PGID" -eq 0 ]]; then
    log_error "PGID/group cannot be 0 (root). Pass your group to the container using the PGID environment variable"
    exit 1
fi

if ! [[ "$PUID" =~ $NUMCHECK ]] ; then
    log_warn "Invalid user id given: %s: $PUID - Container will be created with user id 1000"
    PUID="1000"
elif [[ "$PUID" -eq 0 ]]; then
    log_error "PUID/user cannot be 0 (root). Pass your user to the container using the PUID environment variable"
    exit 1
fi

if [[ $(getent group $PGID | cut -d: -f1) ]]; then
    usermod -a -G "$PGID" "$USER"
else
    groupmod -g "$PGID" "$USER"
fi

if [[ $(getent passwd $PUID | cut -d: -f1) ]]; then
    USER=$(getent passwd $PUID | cut -d: -f1)
else
    usermod -u "$PUID" "$USER"
fi

mkdir -p "$DIR"/{Master,Caves} || exit 1

#set server timezome
if [[ "$TZ" ]]; then
    if [[ -f "/usr/share/zoneinfo/$TZ" ]]; then
        ln -fs "/usr/share/zoneinfo/$TZ" /etc/localtime
        dpkg-reconfigure -f noninteractive tzdata
    else
        log_warn "$TZ is not a valid timezone, check https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
    fi
fi

########################
# SERVER CONFIG PARAMS #
########################

#SERVER_MAX_PLAYER: 6-64
MAX_PLAYERS=${SERVER_MAX_PLAYER}
[[ "$MAX_PLAYERS" =~ ^[0-9]+$ ]] || MAX_PLAYERS=6
MAX_PLAYERS=$(( MAX_PLAYERS < 6 ? 6 : MAX_PLAYERS > 64 ? 64 : MAX_PLAYERS ))

#SERVER_PVP: true | false
[[ "$SERVER_PVP" == "true" || "$SERVER_PVP" == "false" ]] && PVP=$SERVER_PVP || PVP=false

#SERVER_PAUSE_WHEN_EMPTY: true | false
[[ "$SERVER_PAUSE_WHEN_EMPTY" == "true" || "$SERVER_PAUSE_WHEN_EMPTY" == "false" ]] && PAUSE_EMPTY=$SERVER_PAUSE_WHEN_EMPTY || PAUSE_EMPTY=false

#SERVER_PUBLIC_DESC
DESCRIPTION="${SERVER_PUBLIC_DESC:-Friendly server}"

#SERVER_INTENTION:  cooperative, competitive, social, or madness.
INTENTION=$(echo "${SERVER_INTENTION}" | tr '[:upper:]' '[:lower:]')
[[ "$INTENTION" =~ ^(cooperative|competitive|social|madness)$ ]] || INTENTION=cooperative

#SERVER_PASSWORD: 
PASSWORD="${SERVER_PASSWORD:-}"

#SERVER_GAME_MODE:  RELAXED,SURVIVAL,WILDERNESS,ENDLESS,LIGHTS_OUT
GAME_MODE=$(echo "$SERVER_GAME_MODE" | tr '[:lower:]' '[:upper:]')
[[ "$GAME_MODE" =~ ^(RELAXED|SURVIVAL|WILDERNESS|ENDLESS|LIGHTS_OUT)$ ]] || GAME_MODE=ENDLESS

########################
# CREATE CLUSTER FILES #
########################

#cluster.ini
if [[ ! -f "$DIR/cluster.ini" ]]; then 
    touch "$DIR/cluster.ini"
    crudini --set "$DIR/cluster.ini" GAMEPLAY game_mode "$(echo "$SERVER_GAME_MODE" | tr '[:upper:]' '[:lower:]')"
    crudini --set "$DIR/cluster.ini" GAMEPLAY max_players "$MAX_PLAYERS"
    crudini --set "$DIR/cluster.ini" GAMEPLAY pvp "$PVP"
    crudini --set "$DIR/cluster.ini" GAMEPLAY pause_when_empty "$PAUSE_EMPTY"
    crudini --set "$DIR/cluster.ini" NETWORK cluster_intention "$INTENTION"
    crudini --set "$DIR/cluster.ini" NETWORK cluster_description "$DESCRIPTION"
    crudini --set "$DIR/cluster.ini" NETWORK cluster_name "$NAME"
    crudini --set "$DIR/cluster.ini" NETWORK cluster_password "$PASSWORD"
    
     
    crudini --set "$DIR/cluster.ini" MISC console_enabled true
    crudini --set "$DIR/cluster.ini" SHARD shard_enabled true
    crudini --set "$DIR/cluster.ini" SHARD bind_ip 127.0.0.1
    crudini --set "$DIR/cluster.ini" SHARD master_ip 127.0.0.1
    crudini --set "$DIR/cluster.ini" SHARD master_port 10889
    crudini --set "$DIR/cluster.ini" SHARD cluster_key supersecretkey
fi

#Master/server.ini
if [[ ! -f "$DIR/Master/server.ini" ]]; then 
    touch "$DIR/Master/server.ini"
    crudini --set "$DIR/Master/server.ini" NETWORK server_port 11000
    crudini --set "$DIR/Master/server.ini" SHARD is_master true
    crudini --set "$DIR/Master/server.ini" STEAM master_server_port 27018
    crudini --set "$DIR/Master/server.ini" STEAM authentication_port 8768
fi

#Caves/server.ini
if [[ ! -f "$DIR/Caves/server.ini" ]]; then 
    touch "$DIR/Caves/server.ini"
    crudini --set "$DIR/Caves/server.ini" NETWORK server_port 11001
    crudini --set "$DIR/Caves/server.ini" SHARD is_master false
    crudini --set "$DIR/Caves/server.ini" SHARD name Caves
    crudini --set "$DIR/Caves/server.ini" STEAM master_server_port 27019
    crudini --set "$DIR/Caves/server.ini" STEAM authentication_port 8769
fi

#Master/worldgenoverride.lua
if [[ ! -f "$DIR/Master/worldgenoverride.lua" ]]; then 
    {
        echo "return {" 
        echo -e "\toverride_enabled = true,"
        #TODO: PROBAR ESTO
        echo -e "\tpreset = \"$GAME_MODE\","
        echo -e "\toverrides = {},"
        echo "}"
    } > "$DIR/Master/worldgenoverride.lua"
fi
    
#Caves/worldgenoverride.lua
if [[ ! -f "$DIR/Caves/worldgenoverride.lua" ]]; then 
    {
        echo "return {"
        echo -e "\toverride_enabled = true,"
        echo -e "\tpreset = \"DST_CAVE\","
        echo -e "\toverrides = {},"
        echo "}"
    } > "$DIR/Caves/worldgenoverride.lua"
fi

#cluster_token
if [[ ! -f "$DIR/cluster_token.txt" ]] && [[ -n "$SERVER_TOKEN" ]]; then
    echo "$SERVER_TOKEN" > "$DIR/cluster_token.txt"
else
    log_warn "Token is not defined, server will not start. You will need to set up your token in $NAME/cluster_token.txt"
    log_warn "Please visit https://accounts.klei.com/account/game/servers?game=DontStarveTogether"
fi

#creating adminlist file
if [[ ! -f "$DIR/adminlist.txt" ]]; then 
    touch "$DIR/adminlist.txt"
fi

#creating blocklist file
if [[ ! -f "$DIR/blocklist.txt" ]]; then 
    touch "$DIR/blocklist.txt"
fi

#creating whitelist file
if [[ ! -f "$DIR/whitelist.txt" ]]; then 
    touch "$DIR/whitelist.txt"
fi

#creating/cleaning mods file
if [[ ! -f "$MODS_FILE" ]]; then
    touch "$MODS_FILE"
else
    true > "$MODS_FILE"
fi

############################
# CREATE MODS CONFIG FILES #
############################

#adding mods
IFS=';' read -ra MOD_IDS <<< "$SERVERMODS"
for mod_id in "${MOD_IDS[@]}"; do
    echo "ServerModSetup(\"$mod_id\")" >> "$MODS_FILE"
done

#adding mods collections
IFS=';' read -ra MOD_COLLECTION <<< "$SERVERMODCOLLECTION"
for mod_id in "${MOD_COLLECTION[@]}"; do
    echo "ServerModCollectionSetup(\"$mod_id\")" >> "$MODS_FILE"
done

#adding mods config files
if [[ ! -f "$DIR/Master/modoverrides.lua" ]]; then
    touch "$DIR/Master/modoverrides.lua"
fi

MODS_COMBINED="$SERVERMODS;$SERVERMODCOLLECTION"

IFS=';' read -ra MOD_IDS <<< "$MODS_COMBINED"

# Write to the file
{
    echo "return {"
    for mod_id in "${MOD_IDS[@]}"; do
        if [[ -n "$mod_id" ]]; then
            echo "  [\"workshop-${mod_id}\"] = { enabled = true },"
        fi
    done
    echo "}"
} > "$DIR/Master/modoverrides.lua"


#create link for caves, so both will have same config
ln -sf "$DIR/Master/modoverrides.lua" "$DIR/Caves/modoverrides.lua"

chown -R "$PUID":"$PGID" /opt/dst
exec gosu "$USER" "/opt/dst/run.sh" "$@"
