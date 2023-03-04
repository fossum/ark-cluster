#!/usr/bin/env bash

. /shared.sh

function verify_dir {
    # This user space version does not set permissions.

    local dir="$1"
    if [ ! -d $dir ]; then
        mkdir -p $dir || error "Could not create $dir directory."
    fi
}

# Add bash complete for arkmanager
source /etc/bash_completion.d/arkmanager-completion.bash

# Create custom config if not set, use custom config
if [ ! -f /ark/arkmanager.cfg ]; then
    cp /etc/arkmanager/instances/main.cfg /ark/arkmanager.cfg || warn "Could not save default config file."
fi
cp /ark/arkmanager.cfg /etc/arkmanager/instances/main.cfg || warn "Could not save main instance config file."

if [ ! -f /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer  ] || [ ! -f /ark/server/version.txt ]; then
    warn "No game files found. Installing..."
    arkmanager install || error "Could not install game files."
else
    if [ ${BACKUP_ON_STOP} -eq 1 ] && [ "$(ls -A /ark/server/ShooterGame/Saved/SavedArks/)" ]; then
        log "Creating Backup ..."
        arkmanager backup || warn "Could not create backup."
    fi
fi

log "###########################################################################"
log "Installing Mods ..."
arkmanager installmods || error "Could not install mods."

if [ "${BACKUP_TO_LOAD}" != "" ]; then
    log "Restoring from backup..."
    arkmanager restore "/ark/${BACKUP_TO_LOAD}"
fi

log "###########################################################################"
log "Launching ark server ..."
if [ ${UPDATE_ON_START} -eq 1 ]; then
    arkmanager start || error "Could not start server."
else
    arkmanager start -noautoupdate || error "Could not start server."
fi

# Stop server in case of signal INT or TERM
log "###########################################################################"
log "Running ... (waiting for INT/TERM signal)"
trap stop INT
trap stop TERM

read < /tmp/FIFO &
wait
