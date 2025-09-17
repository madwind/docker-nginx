ARG NGINX_VERSION
ARG GEOIPUPDATE_ACCOUNT_ID
ARG GEOIPUPDATE_LICENSE_KEY

FROM nginx:${NGINX_VERSION} AS builder
ARG NGINX_VERSION
WORKDIR /build

RUN apt-get update && \
    apt-get install -y git && \
    curl -L https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx-${NGINX_VERSION}.tar.gz && \
    tar xzvf "nginx-${NGINX_VERSION}.tar.gz" && \
    git clone --recurse-submodules https://github.com/google/ngx_brotli && \
    git clone https://github.com/leev/ngx_http_geoip2_module && \
    cd nginx-${NGINX_VERSION} && \
    params=$(nginx -V | grep configure) && \
    ./configure ${params#*configure arguments: } --add-module=/build/ngx_brotli --add-module=/build/ngx_http_geoip2_module && \
    make -j$(nproc)

FROM maxmindinc/geoipupdate AS geoipupdate

FROM nginx:${NGINX_VERSION}

ARG GEOIPUPDATE_ACCOUNT_ID
ARG GEOIPUPDATE_LICENSE_KEY

ENV GEOIPUPDATE_CONF_FILE=/etc/GeoIP.conf
ENV GEOIPUPDATE_DB_DIR=/usr/share/GeoIP
ENV GEOIPUPDATE_EDITION_IDS=GeoLite2-City

COPY --from=builder /build/nginx-${NGINX_VERSION}/objs/nginx /usr/sbin/nginx
COPY --from=geoipupdate /usr/bin/geoipupdate /usr/bin/geoipupdate
COPY geoip-update.sh /
COPY 40-acme-update.sh 50-envsubst-on-node.sh 60-start-crond.sh /docker-entrypoint.d/

RUN set -ex && \
    wget https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.zip && \
    unzip master.zip -d master && \
    cd /master/acme.sh-master && \
    mkdir /etc/acme && \
    ./acme.sh --install --config-home /etc/acme && \
    echo -e "AccountID ${GEOIPUPDATE_ACCOUNT_ID}\nLicenseKey ${GEOIPUPDATE_LICENSE_KEY}\nEditionIDs ${GEOIPUPDATE_EDITION_IDS}" > "$GEOIPUPDATE_CONF_FILE" && \
    /usr/bin/geoipupdate -d "$GEOIPUPDATE_DB_DIR" -f "$GEOIPUPDATE_CONF_FILE" -v && \
    crontab -l > conf && echo "10 0 * * 3,6 /geoip-update.sh" >> conf && crontab conf && rm -f conf && \
    chmod +x /geoip-update.sh && \
    chmod +x /docker-entrypoint.d/40-acme-update.sh /docker-entrypoint.d/50-envsubst-on-node.sh /docker-entrypoint.d/60-start-crond.sh && \
    rm -rf /var/cache/apk/* \
           /master.zip \
           /master \
           "$GEOIPUPDATE_CONF_FILE"
