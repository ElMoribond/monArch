#!/bin/bash

pacstrap /mnt base base-devel linux linux-firmware intel-ucode openssh dnsmasq usbutils bash-completion mc p7zip unzip net-tools archey3 vnstat hostapd libcanberra libcanberra-pulse 
grub os-prober efibootmgr

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

# 
rm /mnt/etc/resolv.conf
cat <<EOT >> /mnt/etc/resolv.conf
domain loiseliere.lan
search loiseliere.lan

nameserver=127.0.0.1

# Indispensable pour Docker sinon utilisation des DNS Google
nameserver=10.0.0.1
nameserver=192.168.1.1
EOT




cat <<EOT >> 
EOT




cat <<EOT >> 
EOT




cat <<EOT >> 
EOT




cat <<EOT >> 
EOT

