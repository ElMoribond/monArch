#!/bin/bash

wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/10-network.rules -O /mnt/etc/udev/rules.d/10-network.rules
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/WAN.network -O /mnt/etc/systemd/network/WAN.network
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/LAN.network -O /mnt/etc/systemd/network/LAN.network
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/WIFI.network -O /mnt/etc/systemd/network/WIFI.network

mv /mnt/etc/resolv.conf /mnt/etc/resolv.conf.ori
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/resolv.conf -O /mnt/etc/resolv.conf

mv /mnt/etc/dnsmasq.conf /mnt/etc/dnsmasq.conf.ori
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/dnsmasq.conf -O /mnt/etc/dnsmasq.conf

mv /mnt/etc/hostapd/hostapd.conf /mnt/etc/hostapd/hostapd.conf.ori
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/hostapd.conf -O /mnt/etc/hostapd/hostapd.conf

wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/firewall.service -O /mnt/etc/systemd/system/firewall.service
mkdir -p /mnt/srv/scripts/
wget https://raw.githubusercontent.com/ElMoribond/monArch/master/conf_files/firewall.sh -O /mnt/srv/scripts/firewall.sh
chmod +x /mnt/srv/scripts/firewall.sh

sed -i "s/Port 22/Port 53306/g" /mnt/etc/ssh/sshd_config
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /mnt/etc/ssh/sshd_config
