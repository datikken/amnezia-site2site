# Amnezia site2site tunneling VPN


## Start
```bash
sudo bash ./install_amneziawg.sh --protocol=2.0 --isolation=off --keep-packages
```

## Files created
```bash
/etc/amnezia/amneziawg/awg0.conf # серверные Interface и Peer
/root/awg/manage_amneziawg.sh # менеджер клиентов
/root/awg/my_phone.conf # телефон (секретный файл)
/root/awg/my_laptop.conf # компьютер (секретный файл)
/root/awg/site_a.conf ... site_e.conf
awg0 # Linux VPN-интерфейс
awg-quick@awg0 # systemd unit
```

## Debug
```bash
sudo systemctl is-enabled awg-quick@awg0
sudo systemctl is-active awg-quick@awg0
sudo awg show awg0
sudo bash /root/awg/manage_amneziawg.sh list
ip -4 address show dev awg0
ip -4 route show dev awg0
sudo sysctl net.ipv4.ip_forward
```

## LAN debug on VDS
```bash
sudo tcpdump -ni awg0 'host 192.168.55.10 and host 192.168.66.10'
```

## Backup server config
```bash
/awg0.conf \
 /etc/amnezia/amneziawg/awg0.conf.backup-before-DE
```

## Add more peers
```bash
sudo bash /root/awg/manage_amneziawg.sh add site_d site_e
sudo bash /root/awg/manage_amneziawg.sh list
```

## Add lan connectivity to peers
```bash
sudo cp -a /root/awg/site_d.conf /root/awg/site_d.conf.backup-before-lan
sudo cp -a /root/awg/site_e.conf /root/awg/site_e.conf.backup-before-lan
sudo sed -i -E \
 '/^[[:space:]]*AllowedIPs[[:space:]]*=/c\AllowedIPs = 10.9.9.0/24, 192.168.66.0/24' \
 /root/awg/site_d.conf
sudo sed -i -E \
 '/^[[:space:]]*AllowedIPs[[:space:]]*=/c\AllowedIPs = 10.9.9.0/24, 192.168.55.0/24' \
 /root/awg/site_e.conf
for n in site_d site_e; do
 echo "=== $n ==="
 grep -E '^(Address|Endpoint|AllowedIPs)[[:space:]]*=' "/root/awg/$n.conf"
done
```

## Add LAN connectivity to server
```bash
sudo nano /etc/amnezia/amneziawg/awg0.conf

has

# peer site_d
AllowedIPs = 10.9.9.7/32, 192.168.55.0/24
# peer site_e
AllowedIPs = 10.9.9.8/32, 192.168.66.0/24
```

## Force server to reload config without stop
```bash
sudo bash <<'SCRIPT'
set -euo pipefail
umask 077
TMP_CONF=$(mktemp)
trap 'rm -f "$TMP_CONF"' EXIT
awg-quick strip /etc/amnezia/amneziawg/awg0.conf > "$TMP_CONF"
awg syncconf awg0 "$TMP_CONF"
ip -4 route replace 192.168.55.0/24 dev awg0
ip -4 route replace 192.168.66.0/24 dev awg0
ip -4 route show dev awg0
systemctl is-active awg-quick@awg0
SCRIPT
```