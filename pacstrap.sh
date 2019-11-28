#!/bin/bash

if [ -z ${SSID_PASSWORD+x} ]; then
  Variable SSID_PASSWORD indéfinie!
  exit 1
fi

pacstrap /mnt base base-devel linux linux-firmware intel-ucode openssh dnsmasq usbutils bash-completion mc p7zip unzip net-tools archey3 vnstat hostapd libcanberra libcanberra-pulse 
grub os-prober efibootmgr hostapd

genfstab -U -p /mnt >> /mnt/etc/fstab
cat <<EOT >> /mnt/etc/fstab

tmpfs   /tmp    tmpfs  rw,size=2G,noexec,nodev,nosuid,mode=1700 0 0
EOT

# Clavier
cat <<EOT >> /mnt/etc/vconsole.conf
KEYMAP=fr-latin9
FONT=eurlatgr
EOT

# Langue
cat <<EOT >> /etc/locale.conf
LANG=fr_FR.UTF-8
LC_COLLATE=C
EOT
sed -i "s/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/g" /mnt/etc/locale.gen
locale-gen

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
  export PS1="\[$(tput bold)\]\[$(tput setaf 2)\]\u\[$(tput setaf 4)\]@\h \w\[$(tput setaf 4)\] \\$ \[$(tput sgr0)\]"
else
  export PS1="\[$(tput bold)\]\[$(tput setaf 1)\]\u\[$(tput setaf 4)\]@\h \w\[$(tput setaf 4)\] \\$ \[$(tput sgr0)\]"
fi

# Ecran d'accueil archey4
/usr/bin/archey3
EOT
rm /mnt/root/.bash.bashrc

wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/10-network.rules -o /mnt/etc/udev/rules.d/10-network.rules
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/WAN.network -o /mnt/etc/systemd/network/WAN.network
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/LAN.network -o /mnt/etc/systemd/network/LAN.network
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/WIFI.network -o /mnt/etc/systemd/network/WIFI.network

mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.ori
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/resolv.conf -o /mnt/etc/resolv.conf

mv /mnt/etc/dnsmasq.conf /mnt/etc/dnsmasq.conf.ori
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/dnsmasq.conf -o /mnt/etc/dnsmasq.conf

mv /mnt/etc/hostapd/hostapd.conf /mnt/etc/hostapd/hostapd.conf.ori
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/hostapd.conf -o /mnt/etc/hostapd/hostapd.conf

wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/firewall.service -o /mnt/etc/systemd/system/firewall.service
mkdir -p /mnt/srv/scripts/
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/firewall.sh -o /mnt/srv/scripts/firewall.sh
chmod +x /mnt/srv/scripts/firewall.sh

sed -i "s/Port 22/Port 53306/g" /mnt/etc/ssh/sshd_config
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /mnt/etc/ssh/sshd_config
