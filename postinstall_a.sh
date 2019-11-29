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


