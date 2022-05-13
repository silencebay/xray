FROM --platform=${TARGETPLATFORM} debian:bullseye-slim
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG XRAY_VERSION=latest
ARG XRAY_RELEASE_URL=https://api.github.com/repos/XTLS/Xray-core/releases/latest
ARG XRAY_TARGET_COMMITISH

ENV TZ=Asia/Shanghai

RUN set -eux; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        unzip \
        curl \
        ca-certificates \
        jq \
    ; \
    rm -r /var/lib/apt/lists/*; \
    \
# Download Xray binary
    \
    if [ "${TARGETPLATFORM}" = "linux/amd64" ]; then architecture="linux-64" ; fi; \
    if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then architecture="linux-arm64-v8a" ; fi; \
    if [ "${TARGETPLATFORM}" = "linux/arm/v7" ] ; then architecture="linux-arm32-v7a" ; fi; \
    \
    download_url=$(curl -L "${XRAY_RELEASE_URL}" | jq -r --arg architecture "$architecture" '.assets[] | select (.name | contains($architecture) and endswith(".zip")) | .browser_download_url' -); \
    curl -L $download_url -o xray.zip; \
    unzip xray.zip xray -d /usr/local/bin/; \
    chmod +x /usr/local/bin/xray; \
    \
# Download geoip
    \
    curl https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat -o /usr/share/xray/geosite.dat; \
    curl https://github.com/v2fly/geoip/releases/latest/download/geoip.dat -o /usr/share/xray/geoip.dat; \
    \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
    find /usr/local -type f -executable -exec ldd '{}' ';' \
        | awk '/=>/ { print $(NF-1) }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -r apt-mark manual \
    ; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    \
# some test
    xray --version

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

VOLUME /etc/xray
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/usr/local/bin/xray", "-config", "/etc/xray/config.json" ]