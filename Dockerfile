FROM nginx:1.21.4-alpine
MAINTAINER madwind.cn@gmail.com

ADD acme_init.sh /

RUN apk add --no-cache openssl socat && \
    curl https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh | sh -s -- --install-online --config-home /acme && \
    sed -i '3i\sh acme_init.sh' docker-entrypoint.sh && \
    rm -rf /var/cache/apk/*
