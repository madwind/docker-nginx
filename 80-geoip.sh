#!/bin/sh

set -eu

conf_file=${GEOIPUPDATE_CONF_FILE:-/etc/GeoIP.conf}
database_dir=${GEOIPUPDATE_DB_DIR:-/usr/share/GeoIP}

if [ -n "${GEOIPUPDATE_ACCOUNT_ID:-}" ] || [ -n "${GEOIPUPDATE_LICENSE_KEY:-}" ]; then
  if [ -z "${GEOIPUPDATE_ACCOUNT_ID:-}" ] || [ -z "${GEOIPUPDATE_LICENSE_KEY:-}" ]; then
    echo "GeoIP updates require both GEOIPUPDATE_ACCOUNT_ID and GEOIPUPDATE_LICENSE_KEY" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$conf_file")" "$database_dir"
  umask 077
  cat >"$conf_file" <<EOF
AccountID $GEOIPUPDATE_ACCOUNT_ID
LicenseKey $GEOIPUPDATE_LICENSE_KEY
EditionIDs ${GEOIPUPDATE_EDITION_IDS:-GeoLite2-City}
EOF
  chmod 600 "$conf_file"

  if [ -n "${GEOIPUPDATE_HOST:-}" ]; then
    printf 'Host %s\n' "$GEOIPUPDATE_HOST" >>"$conf_file"
  fi
  if [ -n "${GEOIPUPDATE_PROXY:-}" ]; then
    printf 'Proxy %s\n' "$GEOIPUPDATE_PROXY" >>"$conf_file"
  fi
  if [ -n "${GEOIPUPDATE_PROXY_USER_PASSWORD:-}" ]; then
    printf 'ProxyUserPassword %s\n' "$GEOIPUPDATE_PROXY_USER_PASSWORD" >>"$conf_file"
  fi
  if [ -n "${GEOIPUPDATE_PRESERVE_FILE_TIMES:-}" ]; then
    printf 'PreserveFileTimes %s\n' "$GEOIPUPDATE_PRESERVE_FILE_TIMES" >>"$conf_file"
  fi
fi

if [ -s "$conf_file" ]; then
  {
    printf 'GEOIPUPDATE_CONF_FILE=%s\n' "$conf_file"
    printf 'GEOIPUPDATE_DB_DIR=%s\n' "$database_dir"
    printf 'GEOIPUPDATE_VERBOSE=%s\n' "${GEOIPUPDATE_VERBOSE:-}"
    printf '10 0 * * 3,6 root /geoip-update.sh > /proc/1/fd/1 2>/proc/1/fd/2\n'
  } >/etc/cron.d/geoipupdate
  chmod 644 /etc/cron.d/geoipupdate
  echo "GeoIP update schedule installed"
else
  rm -f /etc/cron.d/geoipupdate
  echo "GeoIP updates disabled: no runtime credentials or configuration file"
fi
