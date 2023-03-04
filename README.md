# Docker: ARK: Survival Evolved

Docker build for managing an ARK: Survival Evolved server.

This image uses [Ark Server Tools](https://github.com/arkmanager/ark-server-tools) to manage an ark server and is forked from [turzam/ark](https://hub.docker.com/r/turzam/ark/).

## Features

- Easy install (no steamcmd / lib32... to install)
- Use Ark Server Tools: update/install/start/backup/rcon/mods
- Easy crontab configuration
- Easy access to ark config file
- Mods handling (via Ark Server Tools)
- `Docker stop` is a clean stop
- Auto upgrading of arkmanager

## Usage

Fast & Easy cluster setup via [docker compose](docker-compose.yml).

Fast & Easy server setup :
`docker run -d -p 7778:7778 -p 7778:7778/udp -p 27015:27015 -p 27015:27015/udp -e SESSIONNAME=myserver -e ADMINPASSWORD="mypasswordadmin" --name ark fossum/ark-cluster`

You can map the ark volume to access config files :
`docker run -d -p 7778:7778 -p 7778:7778/udp -p 27015:27015 -p 27015:27015/udp -e SESSIONNAME=myserver -v /my/path/to/ark:/ark --name ark fossum/ark-cluster`
Then you can edit */my/path/to/ark/arkmanager.cfg* (the values override GameUserSetting.ini) and */my/path/to/ark/[GameUserSetting.ini/Game.ini]*

You can manager your server with rcon if you map the rcon port (you can rebind the rcon port with docker):
`docker run -d -p 7778:7778 -p 7778:7778/udp -p 27015:27015 -p 27015:27015/udp -p 32330:32330  -e SESSIONNAME=myserver --name ark fossum/ark-cluster`

You can change server and steam port to allow multiple servers on same host:
*(You can't just rebind the port with docker. It won't work, you need to change STEAMPORT & SERVERPORT variable)*
`docker run -d -p 7779:7779 -p 7779:7779/udp -p 27016:27016 -p 27016:27016/udp -p 32331:32330  -e SESSIONNAME=myserver2 -e SERVERPORT=27016 -e STEAMPORT=7779 --name ark2 fossum/ark-cluster`

You can check your server with :
`docker exec ark arkmanager status`

You can manually update your mods:
`docker exec ark arkmanager update --update-mods`

You can manually update your server:
`docker exec ark arkmanager update --force`

You can force save your server :
`docker exec ark arkmanager saveworld`

You can backup your server :
`docker exec ark arkmanager backup`

You can upgrade Ark Server Tools :
`docker exec ark arkmanager upgrade-tools`

You can use RCON command via docker :
`docker exec ark arkmanager rconcmd ListPlayers`
*Full list of available command [here](http://steamcommunity.com/sharedfiles/filedetails/?id=454529617&searchtext=admin)*

__You can check all available command for arkmanager__ [here](https://github.com/FezVrasta/ark-server-tools/blob/master/README.md)

### Crontab - Job automation

You can easily configure automatic update and backup.
If you edit the file `/my/path/to/ark/crontab` you can add your crontab job.
For example :

```
# Update the server every hours
0 * * * * arkmanager update --warn --update-mods >> /ark/log/crontab.log 2>&1
# Backup the server each day at 00:00  `
0 0 * * * arkmanager backup >> /ark/log/crontab.log 2>&1
```

*You can check [this website](http://www.unix.com/man-page/linux/5/crontab/) for more information on cron.*

After updating the `/my/path/to/ark/crontab` please run the command
`docker exec ark crontab -u steam /ark/crontab`

To add mods, you only need to change the variable ark_GameModIds in *arkmanager.cfg* with a list of your modIds (like this  `ark_GameModIds="987654321,1234568"`). If UPDATE_ON_START is enabled, just restart your docker or use `docker exec ark arkmanager update --update-mods`.

## Recommended Usages

### Simple container

- First run

 ```Bash
 docker run -it --name ark \
  -p 7778:7778 -p 7778:7778/udp \
  -p 27015:27015 -p 27015:27015/udp \
  -p 32330:32330 \
  -e SESSIONNAME=ArkCluster \
  -e ADMINPASSWORD="myp@sswordadm1n" \
  -e TZ=UTC \
  -v /my/path/to/ark:/ark \
  fossum/ark-cluster
  ```

- Wait for ark to be downloaded installed and launched, then Ctrl+C to stop the server.
- Edit */my/path/to/ark/GameUserSetting.ini and Game.ini*
- Edit */my/path/to/ark/arkserver.cfg* to add mods and configure warning time.
- Add auto-update every day and auto-backup by editing */my/path/to/ark/crontab*. [See](#crontab---job-automation)
- Start the container `docker start ark`
- Check your server with: `docker exec ark arkmanager status`

### Docker-Compose

- Modify [docker-compose.yml](docker-compose.yml)
- run `docker-compose up -d ark`

## Variables

- __SESSIONNAME__: Name of your ark server (default: "Ark Docker")
- __SERVER_MAP__: Map of your ark server (default: "TheIsland")
- __SERVER_PASSWORD__: Password of your ark server (default: "")
- __ADMIN_PASSWORD__: Admin password of your ark server (default: "adminpassword")
- __SERVER_PORT__: Ark server port (can't rebind with docker, it doesn't work) (default: 27015)
- __STEAM_PORT__: Steam server port (can't rebind with docker, it doesn't work) (default: 7778)
- __MAX_PLAYERS__: Number of maximum players (default: 70)
- __BACKUP_ON_START__: Backup the server when the container is started. 0: no backup (default: 1)
- __UPDATE_ON_START__: Update the server when the container is started. 0: no update (default: 1)
- __BACKUP_ON_STOP__: Backup the server when the container is stopped. 0: no backup (default: 1)
- __WARN_ON_STOP__: Warn the players before the container is stopped. 0: no warning (default: 1)
- __TZ__: container timezone (for crontab). (default: "UTC").
- __USER_ID__: UID of the user used. Owner of the volume /ark (default: 1000)
- __GROUP_ID__: GID of the user used. Owner of the volume /ark (default: 1000)

## Volumes

- __/ark__: Working directory:
  - /ark/server: Server files and data.
  - /ark/log: logs
  - /ark/backup: backups
  - /ark/arkmanager.cfg: config file for Ark Server Tools
  - /ark/crontab: crontab config file
  - /ark/server/ShooterGame/Saved/Config/LinuxServer/Game.ini: ark Game.ini config file
  - /ark/server/ShooterGame/Saved/Config/LinuxServer/GameUserSetting.ini: ark GameUserSetting.ini config file
  - /ark/template: Default config files
  - /ark/template/arkmanager.cfg: default config file for Ark Server Tools
  - /ark/template/crontab: default config file for crontab
  - /ark/staging: default directory if you use the --downloadonly option when updating.
- __/cluster__: Cluster volume to share with other instances

## Expose

- __STEAMPORT__: Steam port (default: 7778)
- __SERVERPORT__: server port (default: 27015)
- __RCONPORT__: rcon port (default: 32330)

## Known issues

Currently none
