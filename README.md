# docker-nginx

acme

ngx_http_geoip2_module

ngx_brotli

````yaml
version: '3.7'
services:
  nginx:
    image: madwind/nginx
    container_name: nginx
    volumes:
      - /path/nginx.conf:/etc/nginx/nginx.conf
      # 证书位置
      - <path to ssl>:/etc/nginx/ssl
      # acme 配置
      - <path to acme>:/etc/acme
    ports:
      - "80:80"
      - "443:443"
    environment:
      - TZ=Asia/Shanghai
      # 必填
      - EMAIL=a@b.com
      # 域名 空格分隔
      - DOMAIN=a.b.com c.d.com
      #  Maxminds
      - GEOIPUPDATE_ACCOUNT_ID=<ID>
      - GEOIPUPDATE_LICENSE_KEY=<KEY>
      - GEOIPUPDATE_EDITION_IDS=<IDS>
````
