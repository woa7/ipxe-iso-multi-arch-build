#!/bin/bash

list_ips() {
  H='[0123456789ABCDEF]'
  for i in $H$H$H$H$H$H$H$H; do
    if [ -f $i ]; then
      IPO=`echo $i | sed 's/\(..\)/0x\1 /g'`
      IP=`printf "%d.%d.%d.%d" $IPO`
      echo -n "$i=$IP"
      grep ^DEFAULT $i | sed 's/^DEFAULT/:/'
    fi
  done
}

if [ -z "$1" ]; then
  echo "Usage: $0 IP [config]"
  echo "If no config defined, configuration for this IP will be deleted."
  list_ips
  exit 0
fi

IPO=`echo $1 | tr '.' ' '`
FN=`printf "%02x%02x%02x%02x" $IPO | tr a-z A-Z`
shift

if [ -z "$1" ]; then
  if [ -f "$FN" ]; then
    rm -f $FN
  fi
fi

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
