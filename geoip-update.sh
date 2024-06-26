#!/bin/sh

if [ -z "$GEOIPUPDATE_ACCOUNT_ID" ] || [ -z "$GEOIPUPDATE_LICENSE_KEY" ] || [ -z "$GEOIPUPDATE_EDITION_IDS" ]; then
  exit 1
fi

conf_file=/etc/GeoIP.conf
database_dir=/usr/share/GeoIP

if [ -n "$GEOIPUPDATE_CONF_FILE" ]; then
  conf_file=$GEOIPUPDATE_CONF_FILE
fi

if [ -n "$GEOIPUPDATE_DB_DIR" ]; then
  database_dir=$GEOIPUPDATE_DB_DIR
fi

# Create configuration file
echo "# STATE: Creating configuration file at $conf_file"
cat <<EOF >"$conf_file"
AccountID $GEOIPUPDATE_ACCOUNT_ID
LicenseKey $GEOIPUPDATE_LICENSE_KEY
EditionIDs $GEOIPUPDATE_EDITION_IDS
EOF

if [ -n "$GEOIPUPDATE_HOST" ]; then
  echo "Host $GEOIPUPDATE_HOST" >>"$conf_file"
fi

if [ -n "$GEOIPUPDATE_PROXY" ]; then
  echo "Proxy $GEOIPUPDATE_PROXY" >>"$conf_file"
fi

if [ -n "$GEOIPUPDATE_PROXY_USER_PASSWORD" ]; then
  echo "ProxyUserPassword $GEOIPUPDATE_PROXY_USER_PASSWORD" >>"$conf_file"
fi

if [ -n "$GEOIPUPDATE_PRESERVE_FILE_TIMES" ]; then
  echo "PreserveFileTimes $GEOIPUPDATE_PRESERVE_FILE_TIMES" >>"$conf_file"
fi

if [ "$GEOIPUPDATE_VERBOSE" ]; then
  flags="-v"
fi

echo "# STATE: Running geoipupdate"
/usr/bin/geoipupdate -d "$database_dir" -f "$conf_file" $flags
