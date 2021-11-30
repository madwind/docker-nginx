FROM jauderho/nginx-quic
MAINTAINER madwind.cn@gmail.com
ADD acme_init.sh /
RUN apk add --no-cache openssl socat && \
    wget https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.zip && \
    unzip master.zip -d master && \
    mkdir /etc/acme && \
    cd /master/acme.sh-master && \
    ./acme.sh --install --config-home /etc/acme && \
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt && \
    rm -rf /var/cache/apk/* \
           /master \
           /master.zip
           
ENTRYPOINT ["sh","/acme_init.sh"]
