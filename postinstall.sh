#!/bin/bash

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

echo "---------------------------- Configuration de grub"
sed -i '/GRUB_TIMEOUT/c\GRUB_TIMEOUT=1' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "---------------------------- Configuration langue"
cat <<EOT >> /etc/locale.conf
LANG=fr_FR.UTF-8
# Préférer l'anglais à la langue par défaut si la traduction fr n'existe pas
LANGUAGE="fr_FR:en_US"
LC_COLLATE=C
EOT
sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
sed -i "s/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/g" /etc/locale.gen
locale-gen

sed -i "s/DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/g" /etc/systemd/system.conf 

rm -f /root/.bash.bashrc

echo "---------------------------- Vérification langue"
wget -O - https://raw.githubusercontent.com/ElMoribond/monArch/master/locale-check.sh | bash

echo
echo
echo "----------------------------"
echo "Penser au mot de passe user et root"
echo
echo "Prochain script https://tinyurl.com/MonPostinstall02"
echo
echo
