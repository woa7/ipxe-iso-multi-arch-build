#!/bin/bash

if [ -z "$2" ]; then
  echo "Usage: $0 IP config"
  exit 0
fi

IPO=`echo $1 | tr '.' ' '`
FN=`printf "%02x%02x%02x%02x" $IPO | tr a-z A-Z`
shift

cat > $FN << EOF
INCLUDE pxelinux.cfg/fedora
INCLUDE pxelinux.cfg/centos
INCLUDE pxelinux.cfg/custom
DEFAULT $@
TIMEOUT 5
PROMPT 1
EOF

echo "# Filename: $FN"
cat $FN
