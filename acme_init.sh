set -ex
if [ -n "${EMAIL}" -a -n "${DOMAIN}" ]; then
  for domain in ${DOMAIN}
    do
      /root/.acme.sh/acme.sh --register-account -m ${EMAIL} --issue -d ${domain} --standalone
      /root/.acme.sh/acme.sh --install-cert -d ${domain} \
      --key-file       /etc/nginx/ssl/${domain}/key.pem  \
      --fullchain-file /etc/nginx/ssl/${domain}/cert.pem \
      --reloadcmd     "service nginx force-reload"
    done
fi
