FROM nginx:1.21.4-alpine
MAINTAINER madwind.cn@gmail.com

RUN apk add --no-cache socat

USER 101

RUN curl https://get.acme.sh | sh && \
    rm -rf /var/cache/apk/*
