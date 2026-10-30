#!/bin/sh

set -eu

if [ -z "${DOMAINS:-}" ]; then
  exit 0
fi

has_valid_certificate() {
  [ -s "$cert_dir/cert" ] && [ -s "$cert_dir/cert.key" ] && [ -s "$cert_dir/fullchain.cer" ] || return 1
  openssl x509 -in "$cert_dir/fullchain.cer" -noout -checkend 0 >/dev/null 2>&1 || return 1
  cert_public_key=$(openssl x509 -in "$cert_dir/fullchain.cer" -pubkey -noout 2>/dev/null) || return 1
  key_public_key=$(openssl pkey -in "$cert_dir/cert.key" -pubout 2>/dev/null) || return 1
  [ "$cert_public_key" = "$key_public_key" ]
}

DOMAINS=$(printf '%s\n' "$DOMAINS" | envsubst)
account_registered=false

for DOMAIN in $DOMAINS; do
  cert_dir=/etc/nginx/ssl/$DOMAIN
  if has_valid_certificate; then
    echo "Using existing certificate for $DOMAIN; renewal is handled by cron"
    continue
  fi

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

  mkdir -p "$cert_dir"
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

  /root/.acme.sh/acme.sh \
    --config-home /etc/acme \
    --install-cert -d "$DOMAIN" \
    --ecc \
    --cert-file "$cert_dir/cert" \
    --key-file "$cert_dir/cert.key" \
    --fullchain-file "$cert_dir/fullchain.cer" \
    --reloadcmd 'if [ -s /var/run/nginx.pid ]; then /usr/sbin/nginx -t && /usr/sbin/nginx -s reload; fi'

  if ! has_valid_certificate; then
    echo "Installed certificate or private key is invalid for $DOMAIN" >&2
    exit 1
  fi
done
