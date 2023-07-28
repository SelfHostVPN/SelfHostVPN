#!/bin/bash

#Check for root
if [[ $EUID -ne 0 ]]; then
   echo "To install this software, the script must be started with root." 
   exit 1
fi

##System update and install base software
apt-get update && apt-get -y upgrade
apt-get install -y ca-certificates curl gnupg git wget jq

#Fetch external IP
externalIP=$(curl https://4.myip.is/ | jq -r '.ip')
echo IP: $externalIP
echo $externalIP > /home/ip.txt

#Get Random Port for WireGard
WGPort=$((RANDOM % 15000 + 40000))
echo Port: $WGPort
echo $WGPort > /home/port.txt

#Generate Random Passwort
RPW=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 ; echo)
echo Password: $RPW
echo $WGPort > /home/password.txt


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

#Build Apache Webserver Image
git clone https://github.com/SelfHostVPN/ApacheWebServer.git /root/ApacheWebServer
cd /root/ApacheWebServer
docker build -t ApacheWebserver .

#Start Docker Container
docker network create --subnet 192.168.10.0/24 Global
docker run --detach --restart always --name Service.Watchtower --volume /var/run/docker.sock:/var/run/docker.sock -e WATCHTOWER_CLEANUP=true containrrr/watchtower
docker run --detach --restart always --network=Global --ip 192.168.10.20 --name Service.MySQL -e "MYSQL_ROOT_PASSWORD=$RPW" -v /home/Volumes/System/MariaDB:/var/lib/mysql mariadb:10.4.3
docker run --detach --restart always --network=Global --ip 192.168.10.50 --name Applications.Proxy -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy:alpine
docker run --detach --restart always --network=Global --ip 192.168.10.99 --name Applications.WGEasy -e VIRTUAL_PORT=51821 -e VIRTUAL_HOST=wg.hole --user root -e WG_HOST=$externalIP -e WG_PORT=$WGPort -e "PASSWORD=$RPW" -e WG_ALLOWED_IPS=0.0.0.0/0 -e WG_DEFAULT_DNS=192.168.10.100  -e WG_DEFAULT_ADDRESS=192.168.12.x -p $WGPort:51820/udp --privileged --cap-add=CAP_NET_RAW --cap-add=CAP_NET_BIND_SERVICE --cap-add=NET_ADMIN -v /home/Volumes/System/WGEasy:/etc/wireguard weejewel/wg-easy
docker run --detach --restart always --network=Global --ip 192.168.10.100 --name Applications.PiHole -e VIRTUAL_PORT=80 -e VIRTUAL_HOST=pi.hole --cap-add=NET_ADMIN -e TZ=Europe/Berlin -e "WEBPASSWORD=$RPW" -e ServerIP=192.168.10.100 -v /home/Volumes/System/PiHole/data:/etc/pihole/ -v /home/Volumes/System/PiHole/dnsmasq:/etc/dnsmasq.d/ -e INTERFACE=eth0 -e DNSMASQ_LISTENING=all --privileged --cap-add=CAP_NET_RAW --cap-add=CAP_NET_BIND_SERVICE --cap-add=NET_ADMIN pihole/pihole
docker run --detach --restart always --network=Global --ip 192.168.10.101 --name Applications.Dashy -e VIRTUAL_PORT=80 -e VIRTUAL_HOST=start.hole -v /home/Volumes/System/Dashy/dashy-config.yml:/app/public/conf.yml:ro lissy93/dashy:latest


#Set Default Settings
wget -O /home/Volumes/System/PiHole/data/custom.list https://raw.githubusercontent.com/SelfHostVPN/SelfHostVPN/main/custom.list && docker restart Applications.PiHole
wget -O /home/Volumes/System/Dashy/dashy-config.yml https://raw.githubusercontent.com/SelfHostVPN/SelfHostVPN/main/dashy-config.yml && docker restart Applications.Dashy

curl -X POST http://192.168.10.99:51821/api/wireguard/client -H "Content-Type: application/json" -d '{"name":"First VPN Client"}'

