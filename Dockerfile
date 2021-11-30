FROM nginx:1.21.4-alpine
MAINTAINER madwind.cn@gmail.com

ADD acme_init.sh /

RUN apk add --no-cache openssl socat && \
    wget https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.zip && \
    unzip master.zip -d master && \
    mkdir /etc/acme && \
    sh /master/acme.sh-master/acme.sh --install --config-home /acme && \
    sed -i '3i\sh acme_init.sh' docker-entrypoint.sh && \
    rm -rf /var/cache/apk/*
           /master
           /master.zip
