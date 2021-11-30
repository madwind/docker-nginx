if [ -n "${EMAIL}" -a -n "${DOMAIN}" ]; then
  for domain in ${DOMAIN}
    do
      if [ ! -d "/etc/nginx/ssl/${domain}" ]; then
          mkdir -p /etc/nginx/ssl/${domain}
      fi
      /nginx/.acme.sh/acme.sh --register-account -m ${EMAIL} \
                              --issue -d ${domain} \
                              --keylength ec-256 \
                              --standalone \
                              --config-home /etc/acme
      /root/.acme.sh/acme.sh --install-cert -d ${domain} \
                             --ecc \
                             --key-file /etc/nginx/ssl/${domain}/cert.pem \
                             --fullchain-file /etc/nginx/ssl/${domain}/cert.key \
                             --reloadcmd "netstat -anput | grep nginx && nginx -s reload" \
                             --config-home /etc/acme
    done
fi
