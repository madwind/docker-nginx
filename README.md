# docker-nginx

acme

ngx_http_geoip2_module

ngx_brotli

```yaml
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
      #ACME
      ## 域名 空格分隔
      - DOMAINS=a.b.com c.d.com e.NODE_NAME.com
      ## 存在NODE_NAME时候 会替换DOMAINS字符串
      - NODE_NAME=foo 
      ## 存在 /etc/nginx/nginx.conf.template 时 NODE_NAME NODE_IP 替换内容 > /etc/nginx/nginx.conf
      - NODE_IP=0.0.0.0
      ## Zero-ssl
      - EAB_KID=
      - EAB_HMAC_KEY=
      - CF_Token=
      - CF_Zone_ID=
      #  Maxminds
      - GEOIPUPDATE_ACCOUNT_ID=<ID>
      - GEOIPUPDATE_LICENSE_KEY=<KEY>
      - GEOIPUPDATE_EDITION_IDS=<IDS>
```
