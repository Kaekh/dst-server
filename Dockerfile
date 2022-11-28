###########################################################
# Dockerfile that builds a Dont Starve Together server
###########################################################
FROM kaekh/steamcmd

ENV HOME /steam
ENV STEAMAPPID 343050
ENV STEAMAPP dst
ENV STEAMAPPDIR "${HOME}/${STEAMAPP}"
ENV SERVERNAME DSTServer
ENV DLURL https://raw.githubusercontent.com/Kaekh/dst-server/main/scripts/dst_start.sh

#Install and update packages
RUN apt-get update \
        && apt-get install -y --no-install-recommends --no-install-suggests \
                vim \
                wget \
                libgcc1 \
                lib32stdc++6 \
                libcurl4-gnutls-dev

#download start script and init folders
RUN mkdir -p "${STEAMAPPDIR}" \
        && wget --no-cache --max-redirect=30 "${DLURL}" -O "${HOME}/dst_start.sh" \
        && chmod +x "${HOME}/dst_start.sh" \
        && rm -rf /var/lib/apt/lists/*

WORKDIR ${HOME}

CMD ["bash", "dst_start.sh"]
