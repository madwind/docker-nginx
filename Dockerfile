FROM nginx:1.21.4-alpine
MAINTAINER madwind.cn@gmail.com

RUN apk add --no-cache openssl socat && \
    curl https://get.acme.sh | sh && \
    rm -rf /var/cache/apk/*
