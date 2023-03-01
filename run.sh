#!/usr/bin/env bash

function log { echo "`date +\"%Y-%m-%dT%H:%M:%SZ\"`: $@"; }
function warn { >&2 echo "`date +\"%Y-%m-%dT%H:%M:%SZ\"`: $@"; }

function error {
    log "$1"
    exit 1
}

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

function verify_dir {
    local dir="$1"
    if [ ! -d $dir ]; then
        mkdir -p $dir || error "Could not create $dir directory."
    fi
    # Put steam owner of directories (if the uid changed, then it's needed)
    chown -R steam:steam $dir || error "Could not set $dir owner."
    chmod -R 777 $dir || error "Could not set $dir permissions."
}

log "###########################################################################"
log "# Started  - `date`"
log "# Server   - ${SESSION_NAME} (${SERVERMAP})"
log "# Cluster  - ${CLUSTER_ID}"
log "# User     - ${USER_ID}"
log "# Group    - ${GROUP_ID}"
log "###########################################################################"

[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

export TERM=linux

########################
#
# System Setup
#
########################

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

if [ -f /usr/share/zoneinfo/${TZ} ]; then
    log "Setting timezone to ${TZ} ..."
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
else
    warn "Timezone '${TZ}' does not exist!"
fi

########################
#
# File Setup
#
########################

verify_dir /ark
verify_dir /ark/backup
verify_dir /ark/log
verify_dir /ark/server
verify_dir /ark/staging
verify_dir /ark/template
verify_dir /cluster
verify_dir /etc/arkmanager
verify_dir /home/steam
# verify_dir /ark/server/ShooterGame/Saved/SavedArks
# verify_dir /ark/server/ShooterGame/Content/Mods
# verify_dir /ark/server/ShooterGame/Binaries/Linux

########################
#
# CRON Setup
#
########################

if [ ! -f /etc/cron.d/upgradetools ]; then
    echo "0 2 * * Mon root bash -l -c 'yes | arkmanager upgrade-tools >> /ark/log/arkmanager-upgrade.log 2>&1'" > /etc/cron.d/upgradetools
fi

if [ ! -f /etc/cron.d/arkupdate ]; then
    log "Adding update cronjob (${CRON_AUTO_UPDATE}) ..."
    echo "$CRON_AUTO_UPDATE steam bash -l -c 'arkmanager update --update-mods --warn --ifempty --saveworld --backup >> /ark/log/ark-update.log 2>&1'" > /etc/cron.d/arkupdate
fi

if [ ! -f /etc/cron.d/arkbackup ]; then
    log "Adding backup cronjob (${CRON_AUTO_BACKUP}) ..."
    echo "$CRON_AUTO_BACKUP steam bash -l -c 'arkmanager backup >> /ark/log/ark-backup.log 2>&1'" > /etc/cron.d/arkbackup
fi
log "###########################################################################"

########################
#
# Steam User Space
#
########################

log "Dropping to steam user."
su steam -c "bash /user-space.sh"
