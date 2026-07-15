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
      # nginx 自带 envsubst 替换环境变量
      -  <path to conf template>:/etc/nginx/templates/nginx.conf.template
      # 证书位置
      - <path to ssl>:/etc/nginx/ssl
      # acme 配置
      - <path to acme>:/etc/acme
    ports:
      - "443:443"
    environment:
      - TZ=Asia/Shanghai
      # ACME
      ## 域名 空格分隔
      - DOMAINS=a.b.com c.d.com e.NODE_NAME.com
      # Zero-ssl
      - EAB_KID=
      - EAB_HMAC_KEY=
      # CF
      - CF_Token=
      - CF_Zone_ID=
      # Maxminds
      - GEOIPUPDATE_ACCOUNT_ID=<ID>
      - GEOIPUPDATE_LICENSE_KEY=<KEY>
      - GEOIPUPDATE_EDITION_IDS=<IDS>
```
