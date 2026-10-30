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
      libmaxminddb-dev \
      # brotli \
      libbrotli-dev && \
    curl -L https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx-${NGINX_VERSION}.tar.gz && \
    tar xzvf "nginx-${NGINX_VERSION}.tar.gz" && \
    git clone --recurse-submodules https://github.com/google/ngx_brotli && \
    cd nginx-${NGINX_VERSION} && \
    nginx -V > nginx.info 2>&1 && \
    params=$(grep 'configure arguments:' nginx.info | sed 's/^configure arguments: //') && \
    sh -c "./configure $params --with-http_geoip_module --add-module=/build/ngx_brotli" && \
    make -j$(nproc)

FROM maxmindinc/geoipupdate AS geoipupdate

FROM nginx:${NGINX_VERSION}
ARG NGINX_VERSION

ENV GEOIPUPDATE_CONF_FILE=/etc/GeoIP.conf
ENV GEOIPUPDATE_DB_DIR=/usr/share/GeoIP
ENV GEOIPUPDATE_EDITION_IDS=GeoLite2-City

RUN set -ex && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y libbrotli1 socat libmaxminddb0 cron openssl && \
    mkdir /etc/acme && \
    curl https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh | sh -s -- --install-online --config-home /etc/acme && \
    cron_jobs=$(crontab -l) && \
    printf 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n%s\n' "$cron_jobs" | \
      sed '/acme\.sh.*--cron/s|> /dev/null|> /proc/1/fd/1 2>/proc/1/fd/2|' | crontab - && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
           /acme.tar.gz \
           /acme

COPY --from=builder /build/nginx-${NGINX_VERSION}/objs/nginx /usr/sbin/nginx
COPY --from=geoipupdate /usr/bin/geoipupdate /usr/bin/geoipupdate

ARG GEOIPUPDATE_ACCOUNT_ID
ARG GEOIPUPDATE_LICENSE_KEY
RUN set -ex && \
    echo "AccountID ${GEOIPUPDATE_ACCOUNT_ID}\nLicenseKey ${GEOIPUPDATE_LICENSE_KEY}\nEditionIDs ${GEOIPUPDATE_EDITION_IDS}" > "$GEOIPUPDATE_CONF_FILE" && \
    /usr/bin/geoipupdate -d "$GEOIPUPDATE_DB_DIR" -f "$GEOIPUPDATE_CONF_FILE" -v && \
    rm -f "$GEOIPUPDATE_CONF_FILE"

COPY --chmod=755 geoip-update.sh /
COPY --chmod=755 80-geoip.sh 90-acme.sh 99-cron.sh /docker-entrypoint.d/
