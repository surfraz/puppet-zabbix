#!/bin/bash

umask 0077

if [ -r /var/log/zabbix/suid-sgid-files.txt ]; then
  mv -f /var/log/zabbix/suid-sgid-files.txt /var/log/zabbix/suid-sgid-files.txt.old
  chown zabbix /var/log/zabbix/suid-sgid-files.txt.old
fi

for PART in $(grep -v '^#' /etc/fstab | awk '($6 != "0") { print $2 }' ); do
  find $PART -xdev \( -perm -04000 -o -perm -02000 \) -type f -exec md5sum {} \;
done > /var/log/zabbix/suid-sgid-files.txt

chown zabbix /var/log/zabbix/suid-sgid-files.txt
