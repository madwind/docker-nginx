# docker-nginx-acme
用环境变量自动申请证书
version: '3.7'
services:
  nginx:
    image: madwind/nginx
    container_name: nginx
    volumes:
      - /path/nginx.conf:/etc/nginx/nginx.conf
      # 证书位置
      - /path/ssl:/etc/nginx/ssl
    ports:
      - "80:80"
      - "443:443"
    environment:
      - TZ=Asia/Shanghai
      # 必填
      - EMAIL=a@b.com
      # 域名 空格分隔
      - DOMAIN=a.b.com c.d.com
    restart: always
    networks:
      - local-network
    logging:
      driver: "json-file"
      options:
        max-size: "200k"
