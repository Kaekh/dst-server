#!/bin/bash

steam_dir=${HOME}
steam_app=${STEAMAPP}
install_dir="${STEAMAPPDIR}"
dontstarve_dir="$steam_dir/.klei/DoNotStarveTogether"

if [ ! -d "$steam_dir" ]; then
	echo "Error: Missing $steam_dir directory!"
	exit 1
fi

cd "$steam_dir"

bash steamcmd +force_install_dir "$install_dir" +login anonymous +app_update 343050 +quit


if [[ -d "$install_dir/bin64" && -e "$steam_dir/files/dedicated_server_mods_setup.lua" ]]; then
        cp "$steam_dir/files/dedicated_server_mods_setup.lua" "$install_dir/mods/"
fi

cd "$install_dir/bin64"

run_shared=("./dontstarve_dedicated_server_nullrenderer_x64")
run_shared+=(-console)
run_shared+=(-cluster "${SERVERNAME}")
run_shared+=(-monitor_parent_process $$)

"${run_shared[@]}" -shard Caves  | sed 's/^/Caves:  /' &
"${run_shared[@]}" -shard Master | sed 's/^/Master: /'
