#!/usr/bin/env bash

. /shared.sh

if [ ! -f /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer  ] || [ ! -f /ark/server/version.txt ]; then
    warn "No game files found. Installing..."
    arkmanager install || error "Could not install game files."
else
    if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A /ark/server/ShooterGame/Saved/SavedArks/)" ]; then
        log "Creating Backup ..."
        arkmanager backup || warn "Could not create backup."
    fi
fi

log "###########################################################################"
log "Installing Mods ..."
arkmanager installmods || error "Could not install mods."

log "###########################################################################"
log "Launching ark server ..."
if [ ${UPDATEONSTART} -eq 1 ]; then
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
