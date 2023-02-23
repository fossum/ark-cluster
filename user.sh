#!/bin/bash

# Change the UID if needed
if [ ! "$(id -u steam)" -eq "$UID" ]; then
	echo "Changing steam uid to $UID."
	usermod -o -u "$UID" steam ;
fi
# Change gid if needed
if [ ! "$(id -g steam)" -eq "$GID" ]; then
	echo "Changing steam gid to $GID."
	groupmod -o -g "$GID" steam ;
fi

# Set Timezone
if [ -f /usr/share/zoneinfo/${TZ} ]; then
    echo "Setting timezone to '${TZ}'..."
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
else
    echo "Timezone '${TZ}' does not exist!"
fi

# Add Ark Server Tools to Path
export PATH=$PATH:/home/steam/ark-server-tools/:/home/steam/ark-server-tools/tools/


# Put steam owner of directories (if the uid changed, then it's needed)
chown -R steam:steam /ark /home/steam

# avoid error message when su -p (we need to read the /root/.bash_rc )
chmod -R 777 /root/

# Launch run.sh with user steam (-p allow to keep env variables)
su --preserve-environment -c "bash /home/steam/run.sh" steam
