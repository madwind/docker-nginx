#!/bin/sh

if [ -f /etc/nginx/nginx.conf.template ]; then
  envsubst '$NODE_NAME $NODE_IP' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
fi
