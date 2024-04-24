ARG NGINX_VERSION
ARG GEOIPUPDATE_ACCOUNT_ID
ARG GEOIPUPDATE_LICENSE_KEY

FROM nginx:${NGINX_VERSION}-alpine as builder
ARG NGINX_VERSION
WORKDIR /build

# RUN set -ex && \
#     wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
#     tar xzvf nginx-${NGINX_VERSION}.tar.gz && \
#     apk add --no-cache --virtual .build-deps \
#       gcc \
#       libc-dev \
#       make \
#       openssl-dev \
#       pcre-dev \
#       zlib-dev \
#       linux-headers \
#       libxslt-dev \
#       gd-dev \
#       geoip-dev \
#       perl-dev \
#       libedit-dev \
#       bash \
#       alpine-sdk \
#       findutils \
#       libmaxminddb-dev && \
#     # brotil
#     git clone --recurse-submodules https://github.com/google/ngx_brotli && \
#     # geoip2
#     git clone https://github.com/leev/ngx_http_geoip2_module  && \
#     cd nginx-${NGINX_VERSION} && \
#     nginx -V &> nginx.info && \
#     export params=`cat nginx.info | grep configure` && \
#     sh -c "./configure ${params:20} --add-module=/build/ngx_brotli --add-module=/build/ngx_http_geoip2_module" && \
#     make
  
FROM maxmindinc/geoipupdate as geoipupdate
    
FROM nginx:${NGINX_VERSION}-alpine
MAINTAINER madwind.cn@gmail.com

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
    apk add --no-cache openssl socat libmaxminddb pcre && \
    wget https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.zip && \
    unzip master.zip -d master && \
    cd /master/acme.sh-master && \
    mkdir /etc/acme && \
    ./acme.sh --install --config-home /etc/acme && \
    echo ${GEOIPUPDATE_ACCOUNT_ID} && \
    echo -e "AccountID ${GEOIPUPDATE_ACCOUNT_ID}\nLicenseKey ${GEOIPUPDATE_LICENSE_KEY}\nEditionIDs ${GEOIPUPDATE_EDITION_IDS}" > "$GEOIPUPDATE_CONF_FILE" && \
    cat "$GEOIPUPDATE_CONF_FILE" && \
    /usr/bin/geoipupdate -d "$GEOIPUPDATE_DB_DIR" -f "$GEOIPUPDATE_CONF_FILE" -v && \
    crontab -l > conf && echo "10 0 * * 3,6 /geoip-update.sh" >> conf && crontab conf && rm -f conf && \
    chmod +x /geoip-update.sh && \
    chmod +x /docker-entrypoint.d/40-acme-update.sh /docker-entrypoint.d/50-envsubst-on-node.sh /docker-entrypoint.d/60-start-crond.sh && \
    rm -rf /var/cache/apk/* \
           /master.zip \
           /master \
           "$GEOIPUPDATE_CONF_FILE"
