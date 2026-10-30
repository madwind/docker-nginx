#!/bin/sh

set -eu

if [ -z "${DOMAINS:-}" ]; then
  exit 0
fi

install_certificate() {
  mkdir -p "$cert_dir" || return $?
  /root/.acme.sh/acme.sh \
    --config-home /etc/acme \
    --install-cert -d "$DOMAIN" \
    --ecc \
    --cert-file "$cert_dir/cert" \
    --key-file "$cert_dir/cert.key" \
    --fullchain-file "$cert_dir/fullchain.cer" \
    --reloadcmd 'if [ -s /var/run/nginx.pid ]; then /usr/sbin/nginx -t && /usr/sbin/nginx -s reload; fi'
}

DOMAINS=$(printf '%s\n' "$DOMAINS" | envsubst)
account_registered=false

for DOMAIN in $DOMAINS; do
  cert_dir=/etc/nginx/ssl/$DOMAIN
  if install_certificate; then
    echo "Installed local certificate for $DOMAIN; renewal is handled by cron"
    continue
  fi

  echo "Local certificate installation failed for $DOMAIN; attempting issuance"

  if [ -z "${EAB_KID:-}" ] || [ -z "${EAB_HMAC_KEY:-}" ] || [ -z "${CF_Token:-}" ] || [ -z "${CF_Zone_ID:-}" ]; then
    echo "Cannot obtain a certificate for $DOMAIN: EAB_KID, EAB_HMAC_KEY, CF_Token and CF_Zone_ID are required" >&2
    exit 1
  fi

  if [ "$account_registered" = false ]; then
    /root/.acme.sh/acme.sh \
      --config-home /etc/acme \
      --register-account \
      --eab-kid "$EAB_KID" \
      --eab-hmac-key "$EAB_HMAC_KEY"
    account_registered=true
  fi

  issue_status=0
  /root/.acme.sh/acme.sh \
    --config-home /etc/acme \
    --issue -d "$DOMAIN" \
    --keylength ec-256 \
    --dns dns_cf || issue_status=$?

  # acme.sh returns 2 when its saved certificate does not need renewal.
  case "$issue_status" in
    0|2) ;;
    *)
      echo "Certificate issuance failed for $DOMAIN (exit $issue_status)" >&2
      exit "$issue_status"
      ;;
  esac

  install_certificate
done
