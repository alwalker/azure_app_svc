#!/usr/bin/env sh

stress-ng -c 2 &

./docker-entrypoint.sh nginx -g "daemon off;"
