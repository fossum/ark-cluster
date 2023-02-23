#!/usr/bin/env bash

source /etc/container_environment.sh

function log { echo "`date +\"%Y-%m-%dT%H:%M:%SZ\"`: $@"; }

log "###########################################################################"
log "# Started  - `date`"
log "# Server   - ${SESSION_NAME}"
log "# Cluster  - ${CLUSTER_ID}"
log "# User     - ${USER_ID}"
log "# Group    - ${GROUP_ID}"
log "###########################################################################"
[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

export TERM=linux

function stop {
    if [ ${BACKUPONSTOP} -eq 1 ] && [ "$(ls -A /ark/server/ShooterGame/Saved/SavedArks)" ]; then
        log "Creating Backup ..."
        arkmanager backup
    fi
    if [ ${WARNONSTOP} -eq 1 ]; then
        arkmanager stop --warn
    else
        arkmanager stop
    fi
    exit
}

# Change the USER_ID if needed
if [ ! "$(id -u steam)" -eq "$USER_ID" ]; then
    log "Changing steam uid to $USER_ID."
    usermod -o -u "$USER_ID" steam ;
fi
# Change gid if needed
if [ ! "$(id -g steam)" -eq "$GROUP_ID" ]; then
    log "Changing steam gid to $GROUP_ID."
    groupmod -o -g "$GROUP_ID" steam ;
fi

# Change working directory to /ark to allow relative path
cd /ark

# Add a template directory to store the last version of config file
[ ! -d /ark/template ] && mkdir /ark/template
# We overwrite the template file each time
cp /home/steam/arkmanager.cfg /ark/template/arkmanager.cfg
cp /home/steam/crontab /ark/template/crontab
# Creating directory tree && symbolic link
[ ! -f /ark/arkmanager.cfg ] && cp /home/steam/arkmanager.cfg /ark/arkmanager.cfg
[ ! -d /ark/log ] && mkdir /ark/log
[ ! -d /ark/backup ] && mkdir /ark/backup
[ ! -d /ark/staging ] && mkdir /ark/staging

if [ ! -f /etc/cron.d/upgradetools ]; then
    echo "0 2 * * Mon root bash -l -c 'yes | arkmanager upgrade-tools >> /ark/log/arkmanager-upgrade.log 2>&1'" > /etc/cron.d/upgradetools
fi

if [ ! -f /etc/cron.d/arkupdate ]; then
    log "Adding update cronjob (${CRON_AUTO_UPDATE}) ..."
    echo "$CRON_AUTO_UPDATE steam bash -l -c 'arkmanager update --update-mods --warn --ifempty --saveworld --backup >> /ark/log/ark-update.log 2>&1'" > /etc/cron.d/arkupdate
fi

if [ -f /usr/share/zoneinfo/${TZ} ]; then
    log "Setting timezone to ${TZ} ..."
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
fi
    echo "Timezone '${TZ}' does not exist!"
fi

if [ ! -f /etc/cron.d/arkbackup ]; then
    log "Adding backup cronjob (${CRON_AUTO_BACKUP}) ..."
    echo "$CRON_AUTO_BACKUP steam bash -l -c 'arkmanager backup >> /ark/log/ark-backup.log 2>&1'" > /etc/cron.d/arkbackup
fi

# We overwrite the default file each time
cp /home/steam/arkmanager-user.cfg /ark/default/arkmanager.cfg

# Copy default arkmanager.cfg if it doesn't exist
[ ! -f /ark/arkmanager.cfg ] && cp /home/steam/arkmanager-user.cfg /ark/arkmanager.cfg
if [ ! -L /etc/arkmanager/instances/main.cfg ]; then
    rm /etc/arkmanager/instances/main.cfg
    ln -s /ark/arkmanager.cfg /etc/arkmanager/instances/main.cfg
fi

# Put steam owner of directories (if the uid changed, then it's needed)
chown -R steam:steam /ark /home/steam /cluster
log "###########################################################################"

if [ ! -d /ark/server  ] || [ ! -f /ark/server/version.txt ]; then
    log "No game files found. Installing..."
    mkdir -p /ark/server/ShooterGame/Saved/SavedArks
    mkdir -p /ark/server/ShooterGame/Content/Mods
    mkdir -p /ark/server/ShooterGame/Binaries/Linux
    touch /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer
    chown -R steam:steam /ark/server
    arkmanager install
else
    if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A /ark/server/ShooterGame/Saved/SavedArks/)" ]; then
        log "Creating Backup ..."
        arkmanager backup
    fi
fi

log "###########################################################################"
log "Installing Mods ..."
arkmanager installmods

log "###########################################################################"
log "Launching ark server ..."
if [ ${UPDATEONSTART} -eq 1 ]; then
    arkmanager start
else
    arkmanager start -noautoupdate
fi

# Stop server in case of signal INT or TERM
log "###########################################################################"
log "Running ... (waiting for INT/TERM signal)"
trap stop INT
trap stop TERM

read < /tmp/FIFO &
wait
