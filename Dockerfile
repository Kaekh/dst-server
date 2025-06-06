FROM steamcmd/steamcmd

ENV SERVER_NAME=DSTServer \
    SERVER_PUBLIC_DESC="This server is super duper!"\
    SERVER_TOKEN= \
    SERVER_PASSWORD= \
    SERVERMODS= \
    SERVERMODCOLLECTION= \
    SERVER_PORT=16261 \
    SERVER_UDP_PORT=16262 \
    SERVER_GAME_MODE="endless" \
    SERVER_MAX_PLAYER=6 \
    SERVER_PVP=false \
    SERVER_PAUSE_WHEN_EMPTY=true \
    SERVER_INTENTION="cooperative" \
    SERVER_ACTIVE_CAVES=true \
    PUID=1000 \
    PGID=1000

# Install dependencies
RUN apt-get update && \
    arch=$(dpkg --print-architecture) && \
    echo "Architecture: $arch" && \
    if [[ "$arch" == "amd64" ]]; then \
        echo "Installing packages for 64 bits..." && \
        apt-get install -y --no-install-recommends --no-install-suggests \ 
            libcurl4-gnutls-dev \
            libstdc++6:amd64 \
            libgcc-s1:amd64; \
    elif [[ "$arch" == "i386" ]]; then \
        echo "Installing packages for 32 bits..." && \
        dpkg --add-architecture i386 && \
        apt-get install -y --no-install-recommends --no-install-suggests \ 
            libcurl4-gnutls-dev:i386 \
            lib32stdc++6 \
            lib32gcc-s1; \
    else \
        echo -e "\033[0;31mERROR:\033[0mArchitecture $arch not supported" && exit 1; \
    fi

RUN apt-get install -y --no-install-recommends --no-install-suggests \ 
        tzdata \
        vim \
        curl \
        jq \
        crudini \
        screen \
        gosu \
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*;

RUN useradd --no-log-init -d /opt/dst -s /bin/bash dst && \
    gosu nobody true;

COPY setup.sh /
COPY --chown=dst:dst run.sh /opt/dst/

RUN chmod 755 /setup.sh
RUN chmod 755 /opt/dst/run.sh

WORKDIR /opt/dst

EXPOSE 10000-10001/udp 27018-27019/udp

ENTRYPOINT ["/setup.sh"]