#!/bin/bash

if [[ -z ${MON_USER+x} ]]; then
  echo "Variable MON_USER indéfinie !"
  exit 1
fi

timedatectl set-ntp true
echo Europe/Paris > /etc/timezone

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

${MON_USER} ALL=(ALL) NOPASSWD: ALL
EOT
userdel ftp
rm -rf /srv/ftp
rm -f /home/${MON_USER}/.bashrc
echo "exec startplasma-x11" > /home/${MON_USER}/.xinitrc

echo allowed_users=anybody > /etc/X11/Xwrapper.config

cat <<EOT >> /etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
    Identifier         "Keyboard Layout"
    MatchIsKeyboard    "yes"
    Option             "XkbLayout"  "fr"
    Option             "XkbVariant" "latin9" # accès aux caractères spéciaux plus logique avec "Alt Gr" (ex : « » avec "Alt Gr" w x)
EndSection
EOT

cat <<EOT >> /usr/share/sddm/scripts/Xsetup
setxkbmap fr
numlockx
EOT

pacman -S xorg-xinit xorg-xrandr xf86-video-intel plasma-desktop plasma-wayland-session sddm sddm-kcm \
  pulseaudio-zeroconf pulseaudio-jack pulseaudio-equalizer pulseaudio-alsa jack2 notepadqq \
  alsa-utils alsa-firmware libcanberra libcanberra-pulse mosquitto man-db man-pages dolphin \
  python-gobject python-pip python-setuptools numlockx vlc libva-intel-driver mpg123 ttf-dejavu

echo "Penser à copier /srv/mp3/sf-chouette-hulotte-double.ogg /usr/share/sounds/freedesktop/stereo/system-bootup.oga"

cat <<EOT >> /etc/pulse/client.conf

auto-connect-localhost = yes
#default-server = unix:/tmp/pulse-socket
EOT

systemctl enable canberra-system-bootup.service

mkdir /home/${MON_USER}/src
cd /home/${MON_USER}/src
wget -q https://aur.archlinux.org/cgit/aur.git/snapshot/xorgxrdp-git.tar.gz -O ./xorgxrdp-git.tar.gz
wget -q https://aur.archlinux.org/cgit/aur.git/snapshot/xrdp.tar.gz -O ./xrdp.tar.gz
wget -q https://aur.archlinux.org/cgit/aur.git/snapshot/ctop.tar.gz -O ./ctop.tar.gz

touch /modprobe.d/alsa-base.conf
cat <<EOT >> /modprobe.d/alsa-base.conf
options snd_hda_intel index=0
options snd_usb_intel index=1
EOT

pacman -S apache php php-apache 
sed -i 's/;extension=mysqli/extension=mysqli/g' /etc/php/php.ini
sed -i 's/;extension=pdo_mysql/extension=pdo_mysql/g' /etc/php/php.ini
sed -i 's/LoadModule mpm_event_module modules\/mod_mpm_event.so/#LoadModule mpm_event_module modules\/mod_mpm_event.so/g' /etc/httpd/conf/httpd.conf
sed -i 's/#LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/g' /etc/httpd/conf/httpd.conf
cat <<EOF >> /etc/httpd/conf/httpd.conf

# Load php7 module
LoadModule php7_module modules/libphp7.so

# PHP settings
Include conf/extra/php7_module.conf
EOF
systemctl enable httpd
systemctl start httpd

cat <<EOF >> /etc/httpd/conf/extra/httpd-phpmyadmin.conf
Alias /phpmyadmin "/usr/share/webapps/phpMyAdmin"
<Directory "/usr/share/webapps/phpMyAdmin">
    DirectoryIndex index.html index.php
    AllowOverride All
    Options FollowSymlinks
    Require all granted
</Directory>
EOF

cat <<EOF >> /etc/httpd/conf/httpd.conf

# phpMyAdmin configuration
Include conf/extra/httpd-phpmyadmin.conf
EOF
sed -i "s/'localhost';/'127.0.0.1';/g" /etc/webapps/phpmyadmin/config.inc.php

randomBlowfishSecret=`openssl rand -base64 32`;
sed -i "s/blowfish_secret'] = ''/blowfish_secret'] = '$randomBlowfishSecret'/g" /etc/webapps/phpmyadmin/config.inc.php
sed -i "s|//$cfg['DefaultLang'] = 'en';|//$cfg['DefaultLang'] = 'fr';|g" /etc/webapps/phpmyadmin/config.inc.php
cat <<EOF >> /etc/webapps/phpmyadmin/config.inc.php

\$cfg['DefaultLang'] = 'fr';
\$cfg['TempDir'] ='/tmp';
EOF

pip install gTTS
pacman -S espeak-ng mplayer 
for i in `/usr/bin/seq 1 6`; do
  /bin/mkdir -p "/usr/share/mbrola/fr$i" \
  && /usr/bin/wget "https://github.com/numediart/MBROLA-voices/blob/master/data/fr$i/fr$i?raw=true" -O "/usr/share/mbrola/fr$i/fr$i"
done

pacman -S tzdata
timedatectl set-timezone Europe/Paris
timedatectl set-ntp true
