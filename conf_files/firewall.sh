#!/usr/bin/bash
PORTSSH=53306
PORTAVAHI=5353
PORTMQTT=1883
PORTNODERED=1880
PORT_MYADMIN=9001
PORT_WEB="80 443 8080 8081 8082"
PORT_PHPMYADMIN=9001
PORTMYSQL=3306
PORTXRDP="3350 3389 5910"
PORMISTSERVER="4242 8080 1935 554"

IFACE_WAN=WAN
IFACE_LAN=LAN
IFACE_WIFI=WIFI

CIDRLAN=10.0.0.0/24
CIDRWAN=192.168.1.0/24
CIDRWIFI=172.16.0.0/24
VIDEOSUR=10.0.0.2

ipt=/usr/bin/iptables
ip6=/usr/bin/ip6tables
##############################################################################################################################
videosurv_no_net() {
  ## Accès Internet refusés
  NAME=DROPVIDEO;      $ipt -N $NAME; $ipt -A $NAME -j LOG --log-prefix '[IPTABLES DROP YYY] ';   $ipt -A $NAME -j DROP
  $ipt -t filter -A FORWARD -s $VIDEOSUR  -o $IFACE_WAN -j DROP
  $ipt -t filter -A INPUT   -i $IFACE_WAN -d $VIDEOSUR  -j DROPVIDEO
}
translate_nat() {
  ## Translation d'adresses
  for tmp in $CIDRLAN $CIDRWIFI; do
    $ipt -t nat -A POSTROUTING -s $tmp -o $IFACE_WAN  -j MASQUERADE
  done
}
re-init() {
  /usr/bin/rm -f /tmp/firewall.ok
## Réinitialise les règles
  $ipt -t filter -F
  $ipt -t filter -X
  if [[ $1 == "start" ]]; then
    $ipt -t filter -P INPUT   DROP
    $ipt -t filter -P OUTPUT  ACCEPT
    $ipt -t filter -P FORWARD ACCEPT
  else
    $ipt -t filter -P INPUT   ACCEPT
    $ipt -t filter -P OUTPUT  ACCEPT
    $ipt -t filter -P FORWARD ACCEPT
  fi
  $ipt -t nat -F
  $ipt -t nat -X
  $ipt -t mangle -F
  $ipt -t mangle -X
  $ipt -t raw -F
  $ipt -t raw -X
  $ip6 -t filter -P INPUT   DROP
  $ip6 -t filter -P OUTPUT  DROP
  $ip6 -t filter -P FORWARD DROP
  ## RAZ des compteurs
  $ipt -t filter -Z
  $ipt -t nat -Z
  $ipt -t mangle -Z
  $ipt -t raw -Z
}
##############################################################################################################################
start() {
  ## Préfixes de log
  NAME=DROPX;      $ipt -N $NAME; $ipt -A $NAME -j LOG --log-prefix '[IPTABLES DROP] ';       $ipt -A $NAME -j DROP
  ## Boucle locale
  $ipt -t filter -A INPUT -i lo -s 127.0.0.0/8 -j ACCEPT
  videosurv_no_net
  ## Autorise les connexions déjà établies
  $ipt -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
  ## Paquets TCP NEW mal formés
  $ipt -A INPUT -p tcp --tcp-flags ALL NONE    -j DROPX
  $ipt -A INPUT -p tcp --tcp-flags ALL ALL     -j DROPX
  $ipt -A INPUT -m conntrack --ctstate INVALID -j DROPX
  $ipt -t filter -A INPUT -p tcp ! --syn -j DROPX
  ## Chaîne pour empêcher ping flooding, 6/seconde de la même source
  $ipt -N ICMPFLOOD; $ipt -A ICMPFLOOD -m recent --name ICMP --set --rsource
  $ipt -A ICMPFLOOD -m recent --name ICMP --update --seconds 1 --hitcount 6 --rsource --rttl -m limit --limit 1/sec --limit-burst 1 -j LOG --log-prefix '[IPTABLES ICMP-flood] '
  $ipt -A ICMPFLOOD -m recent --name ICMP --update --seconds 1 --hitcount 6 --rsource --rttl -j DROP
  $ipt -A ICMPFLOOD -j ACCEPT
  # Gestion du ping, IMCP conseillé par RFC792
  $ipt -A INPUT -p icmp --icmp-type 0  -m conntrack --ctstate NEW -j ACCEPT
  $ipt -A INPUT -p icmp --icmp-type 3  -m conntrack --ctstate NEW -j ACCEPT
  $ipt -A INPUT -p icmp --icmp-type 8  -m conntrack --ctstate NEW -j ICMPFLOOD
  $ipt -A INPUT -p icmp --icmp-type 11 -m conntrack --ctstate NEW -j ACCEPT
  ## DNS
  $ipt -t filter -A INPUT -p tcp --dport 53 -j ACCEPT
  $ipt -t filter -A INPUT -p udp --dport 53 -j ACCEPT
  ## DHCP
  for tmp in $IFACE_LAN $IFACE_WIFI; do
    $ipt -t filter -I INPUT -i $tmp -p udp --dport 67:68 --sport 67:68 -j ACCEPT
  done

  tmp="$PORTSSH $PORTMYSQL $PORTNODERED $PORTMQTT $PORTXRDP $PORTAVAHI $PORMISTSERVER $PORT_MYADMIN"
  $ipt -t filter -A INPUT  ! -i $IFACE_WAN -p tcp -m multiport --dport ${tmp//[ ]/,} -j ACCEPT
  tmp=$PORT_WEB
  $ipt -t filter -A INPUT  ! -i $IFACE_WAN -p tcp -m multiport --dport ${tmp//[ ]/,} -j ACCEPT

  ## SMTP, IMAP...
  #$ipt -t filter -A INPUT -m multiport -p tcp --dport 25,143,993,995 -m state --state ESTABLISHED     -j ACCEPT
  ##Connexions locales
  $ipt -A INPUT -i $IFACE_LAN  -s $CIDRLAN  -j ACCEPT
  $ipt -A INPUT -i $IFACE_WIFI -s $CIDRWIFI -j ACCEPT
  translate_nat
}
##############################################################################################################################
stop() {
  videosurv_no_net
  translate_nat
}
##############################################################################################################################
#/usr/bin/echo 1 > /proc/sys/net/ipv4/ip_forward
case "$1" in
  start)
    re-init $1
    start
    /usr/bin/echo "normal" > /tmp/firewall.ok
    ;;
  stop)
    re-init $1
    stop
    /usr/bin/echo "mini" > /tmp/firewall.ok
    ;;
  valid)
    cp /srv/scripts/firewall2 /srv/scripts/firewall
    ;;
  *)
    echo "Usage: $0 {start|stop|valid}"
esac
exit 0
