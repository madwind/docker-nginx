if [ -n "${EMAIL}" -a -n "${DOMAIN}" ]; then
  for domain in ${DOMAIN}
    do
      /root/.acme.sh/acme.sh --register-account -m ${EMAIL} --issue -d ${domain} --standalone
      if [ ! -d "/etc/nginx/ssl/${domain}" ]; then
          mkdir -p /etc/nginx/ssl/${domain}
      fi
      /root/.acme.sh/acme.sh --install-cert -d ${domain} \
      --key-file       /etc/nginx/ssl/${domain}/key.pem  \
      --fullchain-file /etc/nginx/ssl/${domain}/cert.pem \
      --reloadcmd     "netstat -anput | grep nginx && nginx -s reload"
    done
fi
