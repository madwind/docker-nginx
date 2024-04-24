#!/bin/sh

if [ -f /etc/nginx/nginx.conf.template ]; then
  envsubst '$NODE' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
fi