#!/bin/bash
# https://tinyurl.com/MonPacstrap01

ok=1
#if [[ ! -d /mnt/boot/efi || ! -d /mnt/home ]]; then
#  echo "Il faut monter les FS !"
#  ok=0
#fi
if [[ -z ${SSID_PASSWORD+x} ]]; then
  echo "Variable SSID_PASSWORD indéfinie !"
  ok=0
fi
if [[ -z ${MON_HOSTN+x} ]]; then
  echo "Variable MON_HOSTN indéfinie !"
  ok=0
fi

if [[ $ok -ne 1 ]]; then
  exit 1
fi

function CheckEx() {
  if [[ $1 -ne 0 ]]; then
    echo "Erreur sur dernière commande -> $2"
    exit 1
  fi
}

umount -R /mnt
mkfs.ext4 -F /dev/nvme0n1p2
CheckEx $? mkfs
mount /dev/nvme0n1p2 /mnt
CheckEx $? mnt
mkdir -p /mnt/boot/efi /mnt/home
CheckEx $? mnt1
mount /dev/nvme0n1p1 /mnt/boot/efi
CheckEx $? mnt2
mount /dev/nvme0n1p5 /mnt/home
CheckEx $? mnt3

#mkdir -p /mnt/var/lib/pacman /mnt/var/cache/pacman/pkg /mnt/var/log /mnt/etc/pacman.d/gnupg
#CheckEx $? mkdir
#pacman-key --init --gpgdir /mnt/etc/pacman.d/gnupg
#CheckEx $? pacman-key
#pacman -r /mnt -b /mnt/var/lib/pacman --cachedir /mnt/var/cache/pacman/pkg --logfile /mnt/var/log/pacman.log --gpgdir /mnt/etc/pacman.d/gnupg -Syu --needed --noconfirm \
#  archlinux-keyring
#CheckEx $? pacman1
#pacman -r /mnt -b /mnt/var/lib/pacman --cachedir /mnt/var/cache/pacman/pkg --logfile /mnt/var/log/pacman.log --gpgdir /mnt/etc/pacman.d/gnupg -Syu --needed --noconfirm \
pacstrap /mnt base base-devel linux linux-firmware openssh dnsmasq bash-completion mc p7zip unzip net-tools grub os-prober efibootmgr \
  archey3 vnstat hostapd pacman-contrib alsa-utils syslog-ng mtools dosfstools \
  ntfs-3g exfat-utils wget htop intel-ucode usbutils nano
CheckEx $? pacstrap

genfstab -U -p /mnt >> /mnt/etc/fstab
cat <<EOT >> /mnt/etc/fstab

tmpfs   /tmp    tmpfs  rw,size=2G,noexec,nodev,nosuid,mode=1700 0 0
EOT

echo $MON_HOSTN > /mnt/etc/hostname
cat /mnt/etc/fstab

# Clavier
cat <<EOT >> /mnt/etc/vconsole.conf
KEYMAP=fr-latin9
FONT=eurlatgr
EOT

cat <<EOT >> /mnt/etc/bash.bashrc
alias_My_NETSTAT() {
  if [ "$1" == "" ]; then
    /usr/bin/netstat -pulnt
  else
    /usr/bin/netstat -pulnt | /usr/bin/grep --color=auto $1
  fi
}
alias_Run_Docker() {
  if [ $# -eq 1 ]; then
    user=""
    if [ "$1" == "mysql" ]; then
      user="mysql"
    elif [ "$1" == "http" ]; then
      user="www-data"
    fi
    if [ "$user" == "" ]; then
      /usr/bin/docker exec -it $1 /bin/bash
    else
      /usr/bin/docker exec -it --user $user $1 /bin/bash
    fi
  fi
}

alias ls='/usr/bin/ls --color=auto -h --group-directories-first'
alias grep='/usr/bin/grep --color=auto'
alias dmesg='/usr/bin/dmesg --ctime --color=always'
alias ..='cd ..'
alias ...='cd ../..'
alias ll='/usr/bin/ls --color=auto -Xal -h --group-directories-first'
alias nstt=alias_My_NETSTAT
alias dockex=alias_Run_Docker
alias lsrecent='/usr/bin/ls --color=auto -utlr'
alias lsnolink='lsrecent | /usr/bin/grep -v ^l'
alias dispo='/usr/bin/df -h | /usr/bin/grep -v tmpfs | /usr/bin/sort -r'
alias free='/usr/bin/free -h --mega -w'
alias ipt='/usr/bin/iptables -n -L | /usr/bin/less'

export LESS="-r"
export EDITOR=nano
export PATH=/srv/scripts/:$PATH

EOT
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/bashrc -O bashrc
cat bashrc >> /mnt/etc/bash.bashrc

echo "---------------------------- Récupère fichiers réseau"
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/10-network.rules -O /mnt/etc/udev/rules.d/10-network.rules
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/WAN.network -O /mnt/etc/systemd/network/WAN.network
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/LAN.network -O /mnt/etc/systemd/network/LAN.network
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/WIFI.network -O /mnt/etc/systemd/network/WIFI.network

echo "---------------------------- Récupère fichiers configuration dnsmasq"
mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.ori
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/resolv.conf -O /mnt/etc/resolv.conf
mv /mnt/etc/dnsmasq.conf /mnt/etc/dnsmasq.conf.ori
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/dnsmasq.conf -O /mnt/etc/dnsmasq.conf

echo "---------------------------- Récupère fichiers hostapd"
mv /mnt/etc/hostapd/hostapd.conf /mnt/etc/hostapd/hostapd.conf.ori
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/hostapd.conf -O /mnt/etc/hostapd/hostapd.conf
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/hostapd.service -O /mnt/etc/systemd/system/hostapd.service
sed -i "s/wpa_passphrase=/wpa_passphrase=${SSID_PASSWORD}/g" /mnt/etc/hostapd/hostapd.conf

echo "---------------------------- Récupère fichiers firewall"
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/firewall.service -O /mnt/etc/systemd/system/firewall.service
mkdir -p /mnt/srv/scripts/
wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/firewall.sh -O /mnt/srv/scripts/firewall
chmod +x /mnt/srv/scripts/firewall

echo "---------------------------- Modif config ssh"
sed -i "s/#Port 22/Port 53306/g" /mnt/etc/ssh/sshd_config
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /mnt/etc/ssh/sshd_config

export LANG=fr_FR.UTF-8

wget -q https://raw.githubusercontent.com/ElMoribond/monArch/master/postinstall.sh -O /mnt/root/Postinstall.sh
chmod +x /mnt/root/Postinstall.sh
echo "---------------------------- Prochaine étapes"
echo "arch-chroot /mn"
echo "/root/Postinstall.sh"
