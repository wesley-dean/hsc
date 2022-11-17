#!/bin/sh

port="${port:-22}"
timeout="${timeout:-300}"
allow_users="${allow_users:-}"

if [ ! -f /etc/ssh/host_rsa_key ] ; then
  dpkg-reconfigure openssh-server
fi

grep -qiEe '^\s*#?\s*PasswordAuthentication' /etc/ssh/sshd_config || printf "PasswordAuthentication no\n" >> /etc/ssh/sshd_config
grep -qiEe '^\s*#?\s*PermitRootLogin' /etc/ssh/sshd_config || printf "PermitRootLogin no\n" >> /etc/ssh/sshd_config
grep -qiEe '^\s*#?\s*Port' /etc/ssh/sshd_config || printf "Port %s\n" "$port" >> /etc/ssh/sshd_config
grep -qiEe '^\s*#?\s*ClientAliveInterval' /etc/ssh_sshd_config || printf "ClientAliveInterval 0\n" >> /etc/ssh/sshd_config

sed -i~ \
  -Ee 's/^[[:space:]]*#*([[:space:]]*PasswordAuthentication[[:space:]]*).*/\1 no/gI' \
  -Ee 's/^[[:space:]]*#([[:space:]]*PermitRootLogin[[:space:]]*).*/\1 no/gI' \
  -Ee "s/^[[:space:]]*#([[:space:]]*Port[[:space:]]*).*/\1 ${port}/gI" \
  -Ee "s/^[[:space:]]*#([[:space:]]*ClientAliveInterval[[:space:]]*).*/\1 ${timeout}/gI" \
  /etc/ssh/sshd_config

if [ -n "${allow_users}" ] ; then
  sed -i~ \
    -Ee "s/^([[:space:]]*#[[:space:]]*AllowUsers[[:space:]]*).*/\1 ${allow_users}/gI" \
    /etc/ssh/sshd_config
fi

cat /etc/ssh/sshd_config

service ssh start

while true ; do
  sleep 1
done
