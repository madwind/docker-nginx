FROM tsuyopon123/nginx-quic
MAINTAINER madwind.cn@gmail.com

ADD acme_init.sh /
RUN apt update && \
    apt install -y wget unzip && \
    wget https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.zip && \
    unzip master.zip -d master && \
    mkdir /etc/acme && \
    cd /master/acme.sh-master && \
    ./acme.sh --install --config-home /etc/acme && \
    rm -rf /master.zip \
           /master
CMD ["sh","/acme_init.sh"]
