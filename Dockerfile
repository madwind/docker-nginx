FROM nginx:1.21.4-alpine
MAINTAINER madwind.cn@gmail.com

ADD acme_init.sh /

RUN apk add --no-cache openssl socat && \
    curl https://get.acme.sh | sh && \
    sed -i '3i\sh acme_init.sh' docker-entrypoint.sh && \
    rm -rf /var/cache/apk/*
