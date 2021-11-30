if [ -n "${EMAIL}" -a -n "${DOMAIN}" ]; then
  for domain in ${DOMAIN}
    do
      /nginx/.acme.sh/acme.sh --register-account -m ${EMAIL} --issue -d ${domain} --keylength ec-256 --standalone --config-home /etc/acme
      if [ ! -d "/etc/nginx/ssl/${domain}" ]; then
          mkdir -p /etc/nginx/ssl/${domain}
      fi
      /nginx/.acme.sh/acme.sh --install-cert -d ${domain} --ecc --config-home /etc/acme \
      --key-file       /etc/nginx/ssl/${domain}/key.pem  \
      --fullchain-file /etc/nginx/ssl/${domain}/cert.pem \
      --reloadcmd     "netstat -anput | grep nginx && nginx -s reload"
    done
fi
nginx -g "deamon off;"
