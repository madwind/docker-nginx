#!/bin/sh

set -eu

conf_file=${GEOIPUPDATE_CONF_FILE:-/etc/GeoIP.conf}
database_dir=${GEOIPUPDATE_DB_DIR:-/usr/share/GeoIP}

if [ ! -s "$conf_file" ]; then
  echo "GeoIP configuration file is missing or empty: $conf_file" >&2
  exit 1
fi

set -- -d "$database_dir" -f "$conf_file"
if [ -n "${GEOIPUPDATE_VERBOSE:-}" ]; then
  set -- "$@" -v
fi

echo "Running geoipupdate"
/usr/bin/geoipupdate "$@"
/usr/sbin/nginx -t
/usr/sbin/nginx -s reload
