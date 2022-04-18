ARG NGINX_VERSION=1.21.6

FROM nginx:${NGINX_VERSION}-alpine as builder

WORKDIR /build

RUN set -ex && \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xzvf nginx-${NGINX_VERSION}.tar.gz && \
    apk add --no-cache --virtual .build-deps \
      gcc \
      libc-dev \
      make \
      openssl-dev \
      pcre-dev \
      zlib-dev \
      linux-headers \
      libxslt-dev \
      gd-dev \
      geoip-dev \
      perl-dev \
      libedit-dev \
      bash \
      alpine-sdk \
      findutils \
      libmaxminddb-dev && \
    git clone https://github.com/google/ngx_brotli && \
    git clone https://github.com/leev/ngx_http_geoip2_module  && \
    cd nginx-${NGINX_VERSION} && \
    nginx -V &> nginx.info && \
    export params=`cat nginx.info | grep configure` && \
    sh -c "./configure ${params:20} --add-module=/build/ngx_brotli --add-module=/build/ngx_http_geoip2_module" && \
    make
  
FROM maxmindinc/geoipupdate as geoipupdate
    
FROM nginx:${NGINX_VERSION}-alpine
MAINTAINER madwind.cn@gmail.com
COPY init.sh geoipupdate.sh /
RUN apk add --no-cache openssl socat libmaxminddb pcre && \
    wget https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.zip && \
    unzip master.zip -d master && \
    cd /master/acme.sh-master && \
    mkdir /etc/acme && \
    ./acme.sh --install && \
    sed -i '3i\sh /init.sh' /docker-entrypoint.sh && \
    crontab -l > conf && echo "10 0 * * * sh /geoipupdate.sh" >> conf && crontab conf && rm -f conf && \
    rm -rf /var/cache/apk/* \
           /master.zip \
           /master

COPY --from=builder /build/nginx-${NGINX_VERSION}/objs/nginx /usr/sbin/nginx
COPY --from=geoipupdate /usr/bin/geoipupdate /usr/bin/geoipupdate
