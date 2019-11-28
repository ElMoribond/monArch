#!/bin/bash

systemctl enable dnsmasq sshd

if [[ -r /srv/vnstat/vnstat.db ]]; then
  systemctl enable vnstat
else
  echo
  echo "--------------->>>>>  Penser à copier les données vnstat"
  echo
fi

echo "---------------------------- Création utilisateur"
useradd -m ${MON_USER}
usermod -aG users,video,audio ${MON_USER}
cat <<EOT >> /etc/sudoers
${MON_USER} ALL=(ALL) NOPASSWD: ALL
EOT

rm -f /home/${MON_USER}/.bash.bashrc

