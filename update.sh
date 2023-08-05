#!/bin/bash

##System update and install base software
echo Update System, Installing curl, wget, jq, gnupg ...
apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1 
DEBIAN_FRONTEND=noninteractive apt-get update -q > /dev/null 2>&1 && apt-get -qy upgrade >/dev/null 2>&1
apt-get install -qy ca-certificates curl gnupg git wget jq  >/dev/null 2>&1

externalIP=$(cat /home/ip.txt) >/dev/null 2>&1
WGPort=$(cat /home/port.txt)
RPW=$(cat /home/password.txt)
SSHPort=$(cat /home/sshport.txt)


#Stop Docker Container
echo Stop docker container..
docker stop Service.MySQL && docker rm Service.MySQL
docker stop Applications.Proxy && docker rm Applications.Proxy
docker stop Applications.WGEasy && docker rm Applications.WGEasy
docker stop Applications.PiHole && docker rm Applications.PiHole
docker stop Applications.Yacy && docker rm Applications.Yacy
docker stop Applications.MeTube && docker rm Applications.MeTube

#Set Default Settings
echo Copy default Settings
wget -q -O /home/Volumes/System/PiHole/data/custom.list https://raw.githubusercontent.com/SelfHostVPN/SelfHostVPN/main/DefaultData/PiHole/custom.list >/dev/null 2>&1

#Recreate Docker Container
echo Recrate docker container..
docker run --detach --restart always --network=Global --ip 192.168.10.20 --name Service.MySQL -e "MYSQL_ROOT_PASSWORD=$RPW" -v /home/Volumes/System/MariaDB:/var/lib/mysql mariadb:10.4.3 >/dev/null 2>&1
docker run --detach --restart always --network=Global --ip 192.168.10.50 --name Applications.Proxy -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy:alpine >/dev/null 2>&1
docker run --detach --restart always --network=Global --ip 192.168.10.99 --name Applications.WGEasy -e VIRTUAL_PORT=51821 -e VIRTUAL_HOST=wg.hole --user root -e WG_HOST=$externalIP -e WG_PORT=$WGPort -e "PASSWORD=$RPW" -e WG_ALLOWED_IPS=0.0.0.0/0 -e WG_DEFAULT_DNS=192.168.10.100  -e WG_DEFAULT_ADDRESS=192.168.12.x -p $WGPort:51820/udp --privileged --cap-add=CAP_NET_RAW --cap-add=CAP_NET_BIND_SERVICE --cap-add=NET_ADMIN -v /home/Volumes/System/WGEasy:/etc/wireguard weejewel/wg-easy >/dev/null 2>&1
docker run --detach --restart always --network=Global --ip 192.168.10.100 --name Applications.PiHole -e VIRTUAL_PORT=80 -e VIRTUAL_HOST=pi.hole --cap-add=NET_ADMIN -e TZ=Europe/Berlin -e "WEBPASSWORD=$RPW" -e ServerIP=192.168.10.100 -v /home/Volumes/System/PiHole/data:/etc/pihole/ -v /home/Volumes/System/PiHole/dnsmasq:/etc/dnsmasq.d/ -e INTERFACE=eth0 -e DNSMASQ_LISTENING=all --privileged --cap-add=CAP_NET_RAW --cap-add=CAP_NET_BIND_SERVICE --cap-add=NET_ADMIN pihole/pihole >/dev/null 2>&1

docker run --detach --restart always --network=Global --ip 192.168.10.110 --name Applications.Yacy -e VIRTUAL_PORT=8090 -e VIRTUAL_HOST=yacy.hole -v /home/Volumes/System/Yacy:/opt/yacy_search_server/DATA --log-opt max-size=20m --log-opt max-file=2 yacy/yacy_search_server:latest
docker run --detach --restart always --network=Global --ip 192.168.10.111 --name Applications.MeTube -e VIRTUAL_PORT=8081 -e VIRTUAL_HOST=metube.hole -v /home/Volumes/System/MeTube:/downloads -e DARK_MODE=true -e DELETE_FILE_ON_TRASHCAN=true  ghcr.io/alexta69/metube
