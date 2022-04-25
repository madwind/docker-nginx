if [ "$GEOIPUPDATE_ACCOUNT_ID" ] && [ "$GEOIPUPDATE_LICENSE_KEY" ] && [ "$GEOIPUPDATE_EDITION_IDS" ]; then
  database_dir=/usr/share/GeoIP
  if [ "$GEOIPUPDATE_DB_DIR" ]; then
    database_dir=$GEOIPUPDATE_DB_DIR
  fi
  if [ -z "$(ls -A "$database_dir")" ]; then
    sh /geoipupdate.sh
  fi
fi

if [ -n "$EAB_KID" ] && [ -n "$EAB_HMAC_KEY" ] && [ -n "$DOMAIN" ]; then
  /root/.acme.sh/acme.sh \
    --config-home /etc/acme \
    --register-account \
    --eab-kid "$EAB_KID" \
    --eab-hmac-key "$EAB_HMAC_KEY"
  if [ ! -d "/etc/nginx/ssl/$DOMAIN" ]; then
    mkdir -p /etc/nginx/ssl/"$DOMAIN"
  fi
  /root/.acme.sh/acme.sh \
    --config-home /etc/acme \
    --issue -d "$DOMAIN" \
    --keylength ec-256 \
    --standalone
  /root/.acme.sh/acme.sh \
    --config-home /etc/acme \
    --install-cert -d "$DOMAIN" \
    --ecc \
    --cert-file /etc/nginx/ssl/"$DOMAIN"/cert \
    --key-file /etc/nginx/ssl/"$DOMAIN"/cert.key \
    --fullchain-file /etc/nginx/ssl/"$DOMAIN"/fullchain.cer \
    --reloadcmd "netstat -anput | grep nginx && nginx -s reload"
fi

if [ ! -d "/usr/local/nginx/proxy_cache" ]; then
  mkdir -p /usr/local/nginx/proxy_cache
fi

envsubst '$NODE' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
