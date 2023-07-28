# Self Hosted VPN Gateway

This is a script for a server on which you want to set up your own VPN server. This offers all the functions that are also available from the large VPN providers.

Other add-ons include some useful functions such as an ad blocker, proxy server, internal network (for gaming and file sharing) and a self-hosted chat to communicate securely with others.

### Quick Deploy

You can easily install the entire system with one command.
This script was made for a new Debian 11 server.
Docker, WG-Easy and Pi-Hole will be installed.

`curl -s https://raw.githubusercontent.com/SelfHostVPN/SelfHostVPN/main/install.sh | bash`

### First Steps after the installation

After installing, you will have no access to any Services yet. All interfaces are only accessible via the VPN. It is also possible to access the services via SSH tunnel.

For the first access we have to use the SSH tunnel.
For instructions, search for "SSH Tunnel" on your favorite search engine.

Settings:
Remote Target IP: 192.168.10.99 Port 51821
Local Port 51821

After that, you can go to http://127.0.0.1:51821 and create your first VPN access.

### First Steps after the installation
How long you are connected with the VPN, you can access any of this Services:

WG-Easy http://192.168.10.99 (http://wg.hole)<br>
Pi-Hole: http://192.168.10.100 (http://pi.hole)
