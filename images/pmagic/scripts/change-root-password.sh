#!/bin/bash

eval "`cat /proc/cmdline | tr ' ' '\n' | grep -e ^password= -e ^passwd=`"

if [ "$passwd" ]; then
  password="$passwd"
fi

if [ "$password" ]; then
  echo "Changing root's password to: $password"
  echo "root:$password" | chpasswd
else
  echo 'root:$1$Nd.xn29E$ZyPRpRorSV06piZyARGxy/' | chpasswd -e
fi
