FROM cm2network/steamcmd:root

# Initial config
ENV SESSIONNAME="Ark Docker" \
    SERVERMAP="TheIsland" \
    SERVERPASSWORD="" \
    ADMINPASSWORD="adm1np@ssword" \
    MAX_PLAYERS=20 \
    UPDATEONSTART=1 \
    BACKUPONSTART=1 \
    SERVERPORT=27015 \
    STEAMPORT=7777 \
    RCONPORT=32330 \
    BACKUPONSTOP=1 \
    WARNONSTOP=1 \
    UID=1000 \
    GID=1000 \
    TZ=UTC \
    TOOLS_GIT_TAG="" \
    GAME_MOD_IDS=""

# Install dependencies
# RUN apt update && \
#     apt install --yes curl cron unzip wget
RUN --mount=type=cache,target=/var/cache/apt \
    apt update && apt install --yes cron git

# Enable passwordless sudo for users under the "sudo" group
# RUN sed -i.bkp -e \
# 	's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers \
# 	/etc/sudoers
    
# Add to sudo group
RUN usermod -aG sudo steam

# Copy & rights to folders
COPY run.sh /home/steam/run.sh
COPY user.sh /home/steam/user.sh
COPY crontab /home/steam/crontab
COPY arkmanager-user.cfg /home/steam/arkmanager.cfg

RUN chmod 777 /home/steam/run.sh \
    && chmod 777 /home/steam/user.sh
RUN mkdir /ark \
    && chown steam /ark && chmod 755 /ark \
    && mkdir /cluster \
    && chown steam /cluster && chmod 755 /cluster

# Get tag version or master.
RUN if [ "$TOOLS_GIT_REF" = '' ]; then \
        TOOLS_GIT_REF='master'; \
    else \
        TOOLS_GIT_REF="$TOOLS_GIT_TAG"; \
    fi; \
    git clone --quiet --depth 1 --branch $TOOLS_GIT_REF \
        https://github.com/arkmanager/ark-server-tools.git /home/steam/ark-server-tools
WORKDIR /home/steam/ark-server-tools/tools
RUN bash ./install.sh steam
RUN ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager # Allow crontab to call arkmanager
RUN (crontab -l 2>/dev/null; echo "* 3 * * Mon yes | arkmanager upgrade-tools >> /ark/log/arkmanager-upgrade.log 2>&1") | crontab -

# Define default config file in /etc/arkmanager
COPY arkmanager-system.cfg /etc/arkmanager/arkmanager.cfg

# Define default config file in /etc/arkmanager
COPY instance.cfg /etc/arkmanager/instances/main.cfg

RUN chown steam -R /ark && chmod 755 -R /ark

# Fix permissions for config files
RUN chown steam -R /etc/arkmanager/instances && chmod 755 -R /etc/arkmanager/instances

EXPOSE ${STEAMPORT} 32330 ${SERVERPORT}
# Add UDP
EXPOSE ${STEAMPORT}/udp ${SERVERPORT}/udp

VOLUME  /ark
VOLUME  /cluster

# Change the working directory to /ark
WORKDIR /ark

# Update game launch the game.
ENTRYPOINT ["/home/steam/user.sh"]
