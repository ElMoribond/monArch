#!/bin/bash

if [[ -z ${MON_USER+x} ]]; then
  echo "Variable MON_USER indéfinie !"
  exit 1
fi

echo "---------------------------- Mot de passe root"
passwd root

rm -f /root/.bash.bashrc

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

echo "---------------------------- Configuration de grub"
sed -i '/GRUB_TIMEOUT/c\GRUB_TIMEOUT=1' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "---------------------------- Configuration langue"
cat <<EOT >> /etc/locale.conf
LANG=fr_FR.UTF-8
LC_COLLATE=C
EOT
sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
sed -i "s/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/g" /etc/locale.gen
locale-gen

useradd -m ${MON_USER}
usermod -aG users,video,audio ${MON_USER}
cat <<EOT >> /etc/sudoers
${MON_USER} ALL=(ALL) NOPASSWD: ALL
EOT
echo "---------------------------- Mot de passe utilisateur"
passwd ${MON_USER}
