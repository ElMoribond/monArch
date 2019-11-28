#!/bin/bash
# https://tinyurl.com/MonPacstrap01

if [[ ! -d /mnt/boot/efi || ! -d /mnt/home ]]; then
  echo "Il faut monter les FS !"
  exit 1
fi

if [[ -z ${SSID_PASSWORD+x} ]]; then
  echo "Variable SSID_PASSWORD indéfinie !"
  exit 1
fi
if [[ -z ${MON_HOSTN+x} ]]; then
  echo "Variable MON_HOSTN indéfinie !"
  exit 1
fi

pacstrap /mnt base base-devel linux linux-firmware intel-ucode openssh dnsmasq usbutils bash-completion mc p7zip unzip \
  net-tools archey3 vnstat hostapd grub os-prober efibootmgr hostapd pacman-contrib alsa-utils syslog-ng mtools dosfstools lsb-
release ntfs-3g exfat-utils pacman-contrib mosquitto

genfstab -U -p /mnt >> /mnt/etc/fstab
cat <<EOT >> /mnt/etc/fstab

tmpfs   /tmp    tmpfs  rw,size=2G,noexec,nodev,nosuid,mode=1700 0 0
EOT

echo $MON_HOSTN > /mnt/etc/hostname

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

# Custom bash prompt via kirsle.net/wizards/ps1.html
if [[ $EUID -ne 0 ]]; then
  PS1=2
else
  PS1=1
fi
export PS1="\[$(tput bold)\]\[$(tput setaf $PS1)\]\u\[$(tput setaf 4)\]@\h \w\[$(tput setaf 4)\] \\$ \[$(tput sgr0)\]"

# Ecran d'accueil archey
/usr/bin/archey3
EOT

echo "---------------------------- Récupère fichiers réseau"
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/10-network.rules -O /mnt/etc/udev/rules.d/10-network.rules
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/WAN.network -O /mnt/etc/systemd/network/WAN.network
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/LAN.network -O /mnt/etc/systemd/network/LAN.network
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/WIFI.network -O /mnt/etc/systemd/network/WIFI.network

echo "---------------------------- Récupère fichiers configuration dnsmasq"
mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.ori
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/resolv.conf -O /mnt/etc/resolv.conf
mv /mnt/etc/dnsmasq.conf /mnt/etc/dnsmasq.conf.ori
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/dnsmasq.conf -O /mnt/etc/dnsmasq.conf

echo "---------------------------- Récupère fichiers hostapd"
mv /mnt/etc/hostapd/hostapd.conf /mnt/etc/hostapd/hostapd.conf.ori
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/hostapd.conf -O /mnt/etc/hostapd/hostapd.conf
sed -i "s/wpa_passphrase=/wpa_passphrase=${SSID_PASSWORD}/g" /mnt/etc/hostapd/hostapd.conf

echo "---------------------------- Récupère fichiers firewall"
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/firewall.service -O /mnt/etc/systemd/system/firewall.service
mkdir -p /mnt/srv/scripts/
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/firewall.sh -O /mnt/srv/scripts/firewall.sh
chmod +x /mnt/srv/scripts/firewall.sh

echo "---------------------------- Modif config ssh"
sed -i "s/Port 22/Port 53306/g" /mnt/etc/ssh/sshd_config
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /mnt/etc/ssh/sshd_config

echo "---------------------------- Installation de grub"
mount | grep efivars &> /dev/null || mount -t efivarfs efivarfs/sys/firmware/efi/efivars
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck

export LANG=fr_FR.UTF-8

echo "---------------------------- Prochaines étapes"
echo "arch-chroot /mnt"
echo "export MON_USER=nom_user"
echo "wget -O - https://tinyurl.com/MonPostinstall01 | bash"
