if [ "$GEOIPUPDATE_ACCOUNT_ID" ] && [ "$GEOIPUPDATE_LICENSE_KEY" ] && [ "$GEOIPUPDATE_EDITION_IDS" ]; then
  database_dir=/usr/share/GeoIP
  if [ "$GEOIPUPDATE_DB_DIR" ]; then
    database_dir=$GEOIPUPDATE_DB_DIR
  fi
  if [ -z "$(ls -A $database_dir)" ]; then
       sh /geoipupdate.sh
  fi
fi

if [ -n "${EMAIL}" -a -n "${DOMAIN}" ]; then
  for domain in ${DOMAIN}
    do
      if [ ! -d "/etc/nginx/ssl/${domain}" ]; then
          mkdir -p /etc/nginx/ssl/${domain}
      fi
      /root/.acme.sh/acme.sh --register-account \
                             --eab-kid ${EAB_KID} \ 
                             --eab-hmac-key ${EAB_KEY} \
                             --issue -d ${domain} \
                             --keylength ec-256 \
                             --standalone \
                             --config-home /etc/acme
      /root/.acme.sh/acme.sh --install-cert -d ${domain} \
                             --ecc \
                             --key-file /etc/nginx/ssl/${domain}/cert.key \
                             --fullchain-file /etc/nginx/ssl/${domain}/cert.pem \
                             --reloadcmd "netstat -anput | grep nginx && nginx -s reload" \
                             --config-home /etc/acme
    done
fi

if [ ! -d "/usr/local/nginx/proxy_cache" ]; then
    mkdir -p /usr/local/nginx/proxy_cache
fi
