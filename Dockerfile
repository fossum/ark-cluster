
FROM cm2network/steamcmd:root

# steam user already exists.

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt \
    apt update && \
    apt upgrade --yes -o Dpkg::Options::="--force-confold" && \
    apt install --yes --no-install-recommends cron git tzdata && \
    apt clean

# Default environment variables
ENV CRON_AUTO_UPDATE="0 */3 * * *" \
    CRON_AUTO_BACKUP="0 */1 * * *" \
    UPDATEONSTART=1 \
    BACKUPONSTART=1 \
    BACKUPONSTOP=1 \
    WARNONSTOP=1 \
    USER_ID=1000 \
    GROUP_ID=1000 \
    TZ=UTC \
    MAX_BACKUP_SIZE=500 \
    SERVERMAP="TheIsland" \
    SESSION_NAME="ARK Cluster" \
    MAX_PLAYERS=20 \
    RCON_ENABLE="True" \
    RCON_PORT=32330 \
    GAME_PORT=7777 \
    QUERY_PORT=27015 \
    RAW_SOCKETS="False" \
    SERVER_PASSWORD="" \
    ADMIN_PASSWORD="" \
    SPECTATOR_PASSWORD="" \
    MODS="" \
    CLUSTER_ID="" \
    KILL_PROCESS_TIMEOUT=300 \
    KILL_ALL_PROCESSES_TIMEOUT=300 \
    TOOLS_GIT_REF=""

# Install Ark Server Tools
# Get tag version or master.
RUN if [ "$TOOLS_GIT_REF" = '' ]; then \
        TOOLS_GIT_REF='master'; \
    else \
        TOOLS_GIT_REF="$TOOLS_GIT_TAG"; \
    fi; \
    git clone --quiet --depth 1 --branch $TOOLS_GIT_REF \
        https://github.com/arkmanager/ark-server-tools.git /home/steam/ark-server-tools && \
    cd /home/steam/ark-server-tools/tools && \
    bash ./install.sh steam && \
    ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager # Allow crontab to call arkmanager
COPY arkmanager.cfg /etc/arkmanager/arkmanager.cfg
COPY arkmanager-user.cfg /home/steam/arkmanager-user.cfg

# Create required directories
RUN mkdir -p /ark \
    mkdir -p /ark/log \
    mkdir -p /ark/backup \
    mkdir -p /ark/staging \
    mkdir -p /ark/default \
    mkdir -p /cluster

COPY crontab /home/steam/crontab

# Setup arkcluster
RUN mkdir -p /etc/service/arkcluster
COPY run.sh /etc/service/arkcluster/run
RUN chmod +x /etc/service/arkcluster/run


# Fix permissions
RUN chown steam -R /ark && chmod 755 -R /ark && \
    chown steam -R /etc/arkmanager/instances && chmod 755 -R /etc/arkmanager/instances && \
    chown steam -R /cluster && chmod 755 -R /cluster

# Skip expose, not all servers will use the same ports.

VOLUME /ark /cluster

# Change the working directory to /ark
WORKDIR /ark

# Update game launch the game.
ENTRYPOINT ["/etc/service/arkcluster/run"]
