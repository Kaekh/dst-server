#!/bin/bash

# ==== General Configuration ====
DIR="/opt/dst"
SCREENNAMEMASTER="dstserverMaster"
SCREENNAMECAVES="dstserverCaves"
LOGFILEMASTER="$DIR/dst_master.log"
LOGFILECAVES="$DIR/dst_caves.log"
BUILDINFO="$DIR/build.info"

UPDATEGAMENEEDED=true
UPDATEMODSNEEDED=true
LASTBUILDVERSION=""

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

# ==== Function to Get Last Build Version from Steam ====
function getLastBuildVersion() {
    local response status version time

    response=$(curl -s https://api.steamcmd.net/v1/info/343050 2>/dev/null)
    status=$(echo "$response" | jq -r '.status' 2>/dev/null)
    version=$(echo "$response" | jq -r '.data."343050".depots.branches.public.buildid' 2>/dev/null)
    time=$(echo "$response" | jq -r '.data."343050".depots.branches.public.timeupdated' 2>/dev/null)

    if [[ "$status" == "success" && -n "$version" && -n "$time" ]]; then
        LASTBUILDVERSION="$version:$time"
    else
        log_error "Couldn't get last version info from Steam API"
    fi
}

# ==== Function to Check if the Game Needs an Update ====
function checkGameUpdate() {
    getLastBuildVersion

    local currentVersion=0
    local currentDate=0

    if [[ -f "$BUILDINFO" ]]; then
        IFS=':' read -r currentVersion currentDate < "$BUILDINFO"
    fi

    if [[ -n "$LASTBUILDVERSION" ]]; then
        IFS=':' read -r newVersion newDate <<< "$LASTBUILDVERSION"

        if [[ "$currentVersion" -ne "$newVersion" || "$currentDate" -lt "$newDate" ]]; then
            UPDATEGAMENEEDED=true
            log_info "Current build: $currentVersion, Last build $newVersion"
        fi
    fi
}

# ==== Function to Check if Mods Need an Update ====
function checkModsUpdate() {
    UPDATEMODSNEEDED=$(
        { [[ -f "$LOGFILEMASTER" ]] && grep -q "needs to be updated" "$LOGFILEMASTER"; } || 
        { [[ -f "$LOGFILECAVES" ]] && grep -q "needs to be updated" "$LOGFILECAVES"; } && 
        echo true || echo false
    )
}

# ==== Function to Send Commands to Servers ====
function sendCommand() {
    local cmd="$1\n"
    screen -S "$SCREENNAMEMASTER" -X stuff "$cmd"
}

# ==== Function for Server Restart Announcements ====
function restartAnnounce() {

    sendCommand "c_announce(\"Server need to be updated!!\")"
    sendCommand "c_announce(\"Server will be restarted in 5 mins, find a safe place and log out please\")"
    sleep 180
    sendCommand "c_announce(\"Server will be restarted in 2 mins, find a safe place and log out please\")"
    sleep 60
    sendCommand "c_announce(\"Server will be restarted in 1 min, find a safe place and log out please\")"
    sleep 30
    sendCommand "c_announce(\"Server will be restarted in 30 seconds, find a safe place and log out please\")"
    sleep 25
    sendCommand "c_announce(\"Server will be restarted in 5 seconds, find a safe place and log out please\")"
    sleep 5
    sendCommand "c_announce(\"Server is restarting NOW!!!\")"

    # Shutdown command after the final announcement
    sendCommand "c_shutdown( true )"
}

# ==== Function to Start the Game Server ====
function startGame() {

    local arch
    local appdir

    arch=$(uname -i)

    # Determine architecture and set up appdir accordingly
    case "$arch" in
        x86_64)
            log_info "x64 Architecture detected"
            appdir="$DIR/server/bin64/dontstarve_dedicated_server_nullrenderer_x64"
            cd "$DIR/server/bin64" || exit 1
            ;;
        x86_32)
            log_info "x32 Architecture detected"
            appdir="$DIR/server/bin/dontstarve_dedicated_server_nullrenderer"
            cd "$DIR/server/bin" || exit 1
            ;;
        *)
            log_error "Architecture $arch is not supported"
            exit 1
            ;;
    esac

    # Ensure mod folder exists and copy the mods setup file
    mkdir -p "$DIR/server/mods"
    cp "$DIR/dedicated_server_mods_setup.lua" "$DIR/server/mods/"

    # Quit any existing screen sessions
    screen -XS "$SCREENNAMEMASTER" quit 2>/dev/null
    screen -XS "$SCREENNAMECAVES" quit 2>/dev/null

    #check for screen log settings file
    if [[ ! -f "$LOGFILEMASTER" ]]; then 
        echo -e "$MSGINFO Creating screen config file for Master... "
        echo "logfile $LOGFILEMASTER" > "$DIR/.screenrcMaster.dst"
        echo "log on"  >> "$DIR/.screenrc.dst"
        echo "logtstamp on" >> "$DIR/.screenrc.dst"
    fi

    if [[ "$SERVER_ACTIVE_CAVES" == true && ! -f "$LOGFILECAVES" ]]; then 
        echo -e "$MSGINFO Creating screen config file for Caves... "
        echo "logfile $LOGFILECAVES" > "$DIR/.screenrcCaves.dst"
        echo "log on"  >> "$DIR/.screenrc.dst"
        echo "logtstamp on" >> "$DIR/.screenrc.dst"
    fi

    log_info "Running server... $(date)"
    date > "$LOGFILEMASTER"
    screen -c "$DIR/.screenrcMaster.dst" -S "$SCREENNAMEMASTER" -L -Logfile "$LOGFILEMASTER" -d -m "$appdir" -cluster "$SERVER_NAME" -shard Master

    if [[ "$SERVER_ACTIVE_CAVES" == true ]]; then
        date > "$LOGFILECAVES"
        screen -c "$DIR/.screenrcCaves.dst" -S "$SCREENNAMECAVES" -L -Logfile "$LOGFILECAVES" -d -m "$appdir" -cluster "$SERVER_NAME" -shard Caves
    fi
}

# ==== Function to Update the Game ====
function updateGame() {
    # If the server is running, announce the restart and stop the screens
    if screen -list | grep -q "$SCREENNAMEMASTER"; then
        restartAnnounce
        sleep 30
        screen -XS "$SCREENNAMEMASTER" quit
        screen -XS "$SCREENNAMECAVES" quit
    fi

    log_info "Updating game via SteamCMD..."
    steamcmd +force_install_dir "$DIR/server" +login anonymous +app_update 343050 +quit
    echo "$LASTBUILDVERSION" > "$BUILDINFO"
    UPDATEGAMENEEDED=false
}

# ==== Main Loop Function ====
function mainLoop() {

    local activeMaster
    local activeCaves

    while true; do
        # Check if mods need updating and if the game needs an update
        checkModsUpdate
        checkGameUpdate

        if [[ "$UPDATEGAMENEEDED" == true || "$UPDATEMODSNEEDED" == true ]]; then
            log_warn "Server needs to be updated..."
            updateGame
        fi

        # Check if the Master and Caves screens are active
        activeMaster=$(screen -list | grep -q "$SCREENNAMEMASTER" && echo true || echo false)
        activeCaves=true

        if [[ "$SERVER_ACTIVE_CAVES" == true ]]; then
            activeCaves=$(screen -list | grep -q "$SCREENNAMECAVES" && echo true || echo false)
        fi

        # If either screen is not active, start the game
        if [[ "$activeMaster" == false || "$activeCaves" == false ]]; then
            startGame
        fi

        # Sleep for 20 minutes before checking again
        sleep 1200
    done
}

# ==== Start the Main Loop ====
mainLoop
