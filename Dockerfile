ARG NGINX_VERSION
ARG GEOIPUPDATE_ACCOUNT_ID
ARG GEOIPUPDATE_LICENSE_KEY

FROM nginx:${NGINX_VERSION} AS builder
ARG NGINX_VERSION
WORKDIR /build

RUN set -ex && \
    apt-get update && \
    apt-get install -y \
      git \
      # nginx \
      gcc \
      make \
      libpcre2-dev \
      zlib1g-dev \
      libssl-dev \
      # brotli \
      libbrotli-dev \
      # ngx_http_geoip2_module \
      libmaxminddb-dev && \
    curl -L https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx-${NGINX_VERSION}.tar.gz && \
    tar xzvf "nginx-${NGINX_VERSION}.tar.gz" && \
    git clone --recurse-submodules https://github.com/google/ngx_brotli && \
    git clone https://github.com/leev/ngx_http_geoip2_module && \
    cd nginx-${NGINX_VERSION} && \
    nginx -V > nginx.info 2>&1 && \
    params=$(grep 'configure arguments:' nginx.info | sed 's/^configure arguments: //') && \
    sh -c "./configure $params --add-module=/build/ngx_brotli --add-module=/build/ngx_http_geoip2_module" && \
    make -j$(nproc)

FROM maxmindinc/geoipupdate AS geoipupdate

FROM nginx:${NGINX_VERSION}
ARG NGINX_VERSION
ARG GEOIPUPDATE_ACCOUNT_ID
ARG GEOIPUPDATE_LICENSE_KEY

ENV GEOIPUPDATE_CONF_FILE=/etc/GeoIP.conf
ENV GEOIPUPDATE_DB_DIR=/usr/share/GeoIP
ENV GEOIPUPDATE_EDITION_IDS=GeoLite2-City

COPY --from=builder /build/nginx-${NGINX_VERSION}/objs/nginx /usr/sbin/nginx
COPY --from=geoipupdate /usr/bin/geoipupdate /usr/bin/geoipupdate
COPY geoip-update.sh /
COPY 99-acme-update.sh /docker-entrypoint.d/

RUN set -ex && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y libmaxminddb0 cron && \
    mkdir /etc/acme && \
    curl https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh | sh -s -- --install-online --config-home /etc/acme && \
    echo "AccountID ${GEOIPUPDATE_ACCOUNT_ID}\nLicenseKey ${GEOIPUPDATE_LICENSE_KEY}\nEditionIDs ${GEOIPUPDATE_EDITION_IDS}" > "$GEOIPUPDATE_CONF_FILE" && \
    /usr/bin/geoipupdate -d "$GEOIPUPDATE_DB_DIR" -f "$GEOIPUPDATE_CONF_FILE" -v && \
    crontab -l > conf && echo "10 0 * * 3,6 /geoip-update.sh" >> conf && crontab conf && rm -f conf && \
    chmod +x /geoip-update.sh && \
    chmod +x /docker-entrypoint.d/99-acme-update.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
           /acme.tar.gz \
           /acme \
           "$GEOIPUPDATE_CONF_FILE"
