#!/bin/bash

if [[ -z ${MON_USER+x} ]]; then
  echo "Variable MON_USER indéfinie !"
  exit 1
fi

systemctl enable systemd-networkd.service dnsmasq.service sshd.service hostapd.service

if [[ -r /srv/vnstat/vnstat.db ]]; then
  systemctl enable vnstat.service
else
  echo
  echo "--------------->>>>>  Penser à copier les données vnstat"
  echo
fi
sed -i 's/Interface ""/Interface "WAN LAN WIFI"/g' /etc/vnstat.conf
sed -i 's/DatabaseDir \"\/var\/lib\/vnstat\"/DatabaseDir \"\/srv\/vnstat\"/g' /etc/vnstat.conf
sed -i 's/ExecStart=\/usr\/sbin\/vnstatd/ExecStart=\/usr\/bin\/vnstatd/g' /usr/lib/systemd/system/vnstat.service

echo "---------------------------- Création utilisateur"
useradd -m ${MON_USER}
usermod -aG users,video,audio ${MON_USER}
cat <<EOT >> /etc/sudoers

userdel ftp
rm -rf /srv/ftp

${MON_USER} ALL=(ALL) NOPASSWD: ALL
EOT
rm -f /home/${MON_USER}/.bash.bashrc

pacman -Syu docker mosquitto 
