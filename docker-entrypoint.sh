#!/bin/bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

if [ ! -z "$PREFER_IPV4" ]; then
    grep -qE '^[ ]*precedence[ ]*::ffff:0:0/96[ ]*100' /etc/gai.conf || echo 'precedence ::ffff:0:0/96  100' | tee -a /etc/gai.conf
elif [ ! -z "$PREFER_IPV6" ]; then
    grep -qE '^[ ]*label[ ]*2002::/16[ ]*2' /etc/gai.conf || echo 'label 2002::/16   2' | tee -a /etc/gai.conf
fi

exec "$@"