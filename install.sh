#!/bin/bash

##System update and install base software
apt-get update && apt-get -y upgrade
apt-get install -y ca-certificates curl gnupg git wget jq

#Fetch external IP
externalIP=$(curl https://4.myip.is/ | jq -r '.ip')
echo IP: $externalIP

#Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Start Docker Container
docker network create --subnet 192.168.10.0/24 Global
docker run --detach --restart always --network=Global --ip 192.168.10.99 --name Applications.WGEasy -e WG_HOST=$externalIP -e "WG_POST_UP=iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" -e "WG_POST_DOWN=iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE" -e Port=80 -e "PASSWORD=" -e WG_ALLOWED_IPS=0.0.0.0/0 -e WG_DEFAULT_DNS=192.168.10.100  -e WG_DEFAULT_ADDRESS=192.168.12.x -p 51820:51820/udp --privileged --cap-add=CAP_NET_RAW --cap-add=CAP_NET_BIND_SERVICE --cap-add=NET_ADMIN weejewel/wg-easy
docker run --detach --restart always --network=Global --ip 192.168.10.100 --name Applications.PiHole --cap-add=NET_ADMIN -e TZ=Europe/Berlin -e "WEBPASSWORD=" -e ServerIP=192.168.10.100 -v /home/Volumes/System/PiHole/data:/etc/pihole/ -v /home/Volumes/System/PiHole/dnsmasq:/etc/dnsmasq.d/ -e INTERFACE=eth0 -e DNSMASQ_LISTENING=all --privileged --cap-add=CAP_NET_RAW --cap-add=CAP_NET_BIND_SERVICE --cap-add=NET_ADMIN pihole/pihole


