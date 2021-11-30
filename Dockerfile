FROM tsuyopon123/nginx-quic
MAINTAINER madwind.cn@gmail.com

ADD acme_init.sh /
RUN apt update && \
    apt install -y git && \
    git clone https://github.com/acmesh-official/acme.sh.git && \
    cd acme.sh && \
    mkdir /etc/acme && \
    ./acme.sh --install --config-home /etc/acme && \
    rm -rf /acme.sh
CMD ["sh","/acme_init.sh"]
