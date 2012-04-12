#!/bin/bash

nated() {
  echo -n "10.*,"
  for i in `seq 16 31`; do
    echo -n "172.$i.*,"
  done
  echo -n "192.168.*"
}

mkdir -p /root/.ssh
cat << EOF >> /root/.ssh/authorized_keys
from="work.salstar.sk,158.197.240.41,`nated`" ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAou3n+SuHVsuM5QXAKnIKilPHnJdKm/KP31Ho2VahJIC7mK0+snbXZYXeQmnwYvqQaDVCl8p0ANMonbs189t+RdBZ86Yq6/boc7zhyrj3gqzflsjyGWp5Gfo2AGQ9pgW3JMHefHMMXqF2uB9pT7PRL873gGfMG1WE3W+loFpDYPgg5TQvDifDP+cnlEdT/30JROFBbJ6sJro5la+7vZT/Yd9JOyNSvjizSsqLyva/t1zhQ2Bb37xGJOgVoRc1Hj+fYe1+jaD2ebtGWWIykvfIb33tpoBg3KkN01rrniTiVD8t1yNPGxc9VecqJoK5QJOCZ6zpjeFtvmiZwdd9bgfznQ== ondrejj@work.salstar.sk
EOF

cat << EOF >> /root/.ssh/known_hosts
salstar.sk,158.197.240.41 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAqHTyvB4zPeybTVgsLMtTAnpZjPMXiULuDfrl2AkCXq4ghvdcUrW00Kqa48OM6Roymq15iBvxncRrXtczw76rc6CRRpiNo2Z+p5PES0TbokMkJlfZa1/VOydUbtjvKpQWunUdbK2LZc/Fmn7otMvso96FnuNAdQyb1En3ICxxTqc=
EOF

chmod g-w /root/.ssh /root/.ssh/authorized_keys /root/.ssh/known_hosts
