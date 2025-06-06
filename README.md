# Don't Starve Together Dedicated Server

Dockerized version of [Don't Starve Together](https://store.steampowered.com/app/322330/Dont_Starve_Together/) dedicated server.

## Setup

You'll need to bind a local directory to the Docker container's `/opt/dst/.klei/DoNotStarveTogether` directory. This directory will hold the following directories:

-   `/Logs` - folder with history logs
-   `/Saves` - folder with server files
-   `/Server` - folder with server options
-   `/backups` - folder with backups
-   `/db` - folder with database of game
-   `/options.ini` - file with configuration to start up server
-   `/server-console.txt` - file with logs of server


```bash
docker run \
--detach \
--name=dst \
--restart unless-stopped \
--volume /path/to/server:/opt/dst/.klei/DoNotStarveTogether \
--env SERVER_NAME=ServerName \
--env SERVER_PASSWORD=serverpassword
--env SERVER_GAME_MODE=survival
--env SERVER_INTENTION=cooperative
--env SERVER_PUBLIC_DESC="public descripcion"
--env SERVER_TOKEN=
--env SERVERMODS=
--env SERVERMODCOLLECTION=
--env PUID=1000
--env PGID=1000
--env TZ=
--publish 10000:10000/udp \
--publish 10001:10001/udp \
--publish 27018:27018/udp \
--publish 27019:27019/udp \
kaekh/dst:latest
```

<details> 
<summary>Explanation of the command</summary>

* `--detach` -> Starts the container detached from your terminal<br> 
* `--name` -> Gives the container a unique name
* `--restart unless-stopped` -> Automatically restarts the container unless the container was manually stopped
* `--volume` -> Binds the DST server folder to the folder you specified
Allows you to easily access your server files
* For the environment (`--env`) variables please see [here](https://github.com/Kaekh/dst-server/edit/main/README.md#environment-variables)
* `--publish` -> Specifies the ports that the container exposes<br> 
</details>

### Docker Compose

If you're using [Docker Compose](https://docs.docker.com/compose/):

```yaml
version: '3.9'
services:
  dst-server:
    image: kaekh/dst:latest
    container_name: dst
    restart: "unless-stopped"
    environment:
      - SERVER_NAME=ServerName
      - SERVER_PASSWORD=serverpassword
      - SERVER_GAME_MODE=
      - SERVER_INTENTION=
      - SERVER_PUBLIC_DESC=
      - SERVER_TOKEN=
      - SERVERMODS=
      - SERVERMODCOLLECTION=
      - PUID=1000
      - PGID=1000
      - TZ=
    ports:
        - "10000:10000/udp"
        - "10001:10001/udp"
        - "27018:27018/udp"
        - "27019:27019/udp"
    volumes:
        - ./server:/opt/dst/.klei/DoNotStarveTogether
```

## Environment Variables

| Parameter                 | Default          | Function                                                        |
|---------------------------|:----------------:|-----------------------------------------------------------------|
| `SERVER_NAME`             |   `ServerName`   | name of the server                                              |
| `SERVER_PASSWORD`         | `serverpassword` | password to login into server                                   |
| `SERVER_MAX_PLAYER`       |       `6`        | number of players                                               |
| `SERVER_PAUSE_WHEN_EMPTY` |     `true`       | pause server when is empty                                      |
| `SERVER_PVP`              |     `false`      | pvp is allowed                                                  |
| `SERVER_GAME_MODE`        |    `endless`     | server game mode                                                |
| `SERVER_INTENTION`        |  `cooperative`   | server intention gameplay                                       |
| `SERVER_ACTIVE_CAVES`     |     `true`       | run caves server                                                |
| `SERVER_PUBLIC_DESC`      |        ``        | server public description                                       |
| `SERVER_TOKEN`            |        ``        | server token MUST be filled for the server to start, check [Klei account](https://github.com/Kaekh/dst-server/edit/main/README.md#klei-account)    |
| `SERVERMODS`              |        ``        | list of mods ids separated by ; check [Modding](https://github.com/Kaekh/dst-server/edit/main/README.md#modding)        |
| `SERVERMODCOLLECTION`     |        ``        | list of mods collection ids separated by ; check [Modding](https://github.com/Kaekh/dst-server/edit/main/README.md#modding)     |
| `PGID`                    |      `1000`      | set the group ID of the user the server will run as             |
| `PUID`                    |      `1000`      | set the user ID of the user the server will run as              |
| `TZ`                      |        ``        | server time zone [TZ list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)              |


## Modding

Mods are supported via steam. To intall them id from workshop and name is needed

-   WorkshopID can be found in [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=347079953)<br>
     In this example 347079953 is the Workshop ID<br>

NOTE: Mods can also be found in collections. In this case, the collection ID needs to be set in SERVERMODCOLLECTION.<br>
    
To install this mod we will use SERVERMODS environment var for single mods and SERVERMODCOLLECTION for collections. In case to install multiple mods they have to be separated by ;<br>


## Klei account

Server Token is needed for server to start. You can create your server token in your [Klei account](https://accounts.klei.com/account/game/servers?game=DontStarveTogether)
