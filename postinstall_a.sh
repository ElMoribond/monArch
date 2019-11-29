#!/bin/bash

if [[ -z ${MON_USER+x} ]]; then
  echo "Variable MON_USER indéfinie !"
  exit 1
fi

systemctl enable systemd-networkd.service dnsmasq.service sshd.service hostapd.service

echo
echo "--------------->>>>>  Penser à copier les données vnstat"
echo
sed -i 's/Interface ""/Interface "WAN LAN WIFI"/g' /etc/vnstat.conf
sed -i 's/ExecStart=\/usr\/sbin\/vnstatd/ExecStart=\/usr\/bin\/vnstatd/g' /usr/lib/systemd/system/vnstat.service

echo "---------------------------- Création utilisateur"
useradd -m ${MON_USER}
usermod -aG users,video,audio ${MON_USER}
cat <<EOT >> /etc/sudoers

userdel ftp
rm -rf /srv/ftp

${MON_USER} ALL=(ALL) NOPASSWD: ALL
EOT
rm -f /home/${MON_USER}/.bashrc

#pacman -Syu docker mosquitto man-db man-pages
#pacman -S plasma-wayland-session sddm sddm-kcm 
#plasma-desktop
