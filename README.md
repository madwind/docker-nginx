# docker-nginx

acme

ngx_http_geoip_module

ngx_brotli

使用官方 GeoIP 模块，构建时通过 `--with-http_geoip_module` 静态启用，保留 `libmaxminddb` 依赖。

从第三方 `ngx_http_geoip2_module` 迁移时，需要将 `http` 中原来的 `geoip2` 配置块替换为：

```nginx
geoip_city /usr/share/GeoIP/GeoLite2-City.mmdb;
```

配置中的变量也需要同步替换：

| 原变量 | 官方模块变量 |
| --- | --- |
| `$geoip2_data_country_code` | `$geoip_city_country_code` |
| `$geoip2_data_country_name` | `$geoip_city_country_name` |
| `$geoip2_data_city_name` | `$geoip_city` |
| `$geoip2_data_province_name` | `$geoip_region_name` |

现有 `GeoLite2-City.mmdb` 可继续使用。`geoip-update.sh` 会在数据库更新成功后执行
`nginx -t && nginx -s reload`，让运行中的 NGINX 重新加载数据库。

启动时，`80-geoip-cron.sh` 会将运行时的 GeoIP 凭据写入权限为 `600` 的配置文件，
并安装每周三、周六更新的 cron 任务。任务直接读取配置文件，不依赖容器环境变量，
输出写入容器日志。也可以直接挂载配置文件，通过 `GEOIPUPDATE_CONF_FILE` 指定路径；
如果没有运行时凭据或配置文件，则不启用 GeoIP 定时更新。

`90-acme.sh` 会检查已有证书的有效期及私钥是否匹配，可用时直接跳过启动签发。
缺失或不可用时才执行签发、安装，失败会终止启动；后续续期由 acme.sh 的 cron 任务处理。
续期任务配置了包含 NGINX 的 `PATH`，输出也写入容器日志。
请同时持久化 `/etc/acme` 和 `/etc/nginx/ssl`，保留续期所需的账号信息与证书。

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
