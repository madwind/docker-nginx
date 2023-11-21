#!/bin/sh

if [ -n "$EAB_KID" ] && [ -n "$EAB_HMAC_KEY" ] && [ -n "$DOMAIN" ] && [ -n "$MAIL" ] && [ -n "$CF_Token" ] && [ -n "$CF_Zone_ID" ]; then
  /root/.acme.sh/acme.sh \
    --config-home /etc/acme \
    --register-account \
    -m "$MAIL" \
    --server google \
    --eab-kid "$EAB_KID" \
    --eab-hmac-key "$EAB_HMAC_KEY"
  if [ ! -d "/etc/nginx/ssl/$DOMAIN" ]; then
    mkdir -p /etc/nginx/ssl/"$DOMAIN"
  fi
  /root/.acme.sh/acme.sh \
    --config-home /etc/acme \
    --issue -d "$DOMAIN" \
    --keylength ec-256 \
    --dns dns_cf
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
