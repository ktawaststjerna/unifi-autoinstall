#!/bin/bash

#=====================================================================================
# Author: Michael Tabor
# Website: https://miketabor.com
# Description: Script to automate the updating and securing of a Ubuntu server and
#              installing the Ubiquiti UniFi controller software.
#
#=====================================================================================


# Update apt-get source list and upgrade all packages.
sudo apt-get update && sudo apt-get upgrade -y

# Allow SSH and UniFi ports on UFW firewall.
sudo ufw allow 22/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw allow 8843/tcp
sudo ufw allow 8880/tcp
sudo ufw allow 3478/udp

# Enable UFW firewall.
sudo ufw --force enable

# Add Ubiquiti UniFi repo to system source list.
sudo echo 'deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti' | sudo tee -a /etc/apt/sources.list.d/100-ubnt.list

# Add Ubiquiti GPG Keys
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50 && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10

# Update source list to include the UniFi repo then install Ubiquiti UniFi.
sudo apt-get update && sudo apt-get install unifi -y

# Install Fail2Ban
sudo apt-get install fail2ban -y

# Copy config Fail2ban config files to preserve overwriting changes during Fail2ban upgrades.
sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Create ubiquiti Fail2ban definition and set fail regex. 
sudo echo -e '# Fail2Ban filter for Ubiquiti UniFi\n#\n#\n\n[Definition]\nfailregex =^.*Failed .* login .* <HOST>*\s*$
' | sudo tee -a /etc/fail2ban/filter.d/ubiquiti.conf

# Add ubiquiti JAIL to Fail2ban setting log path and blocking IPs after 3 failed logins within 15 minutes for 1 hour.
sudo echo -e '\n[ubiquiti]\nenabled  = true\nfilter   = ubiquiti\nlogpath  = /usr/lib/unifi/logs/server.log\nmaxretry = 3\nbantime = 3600\nfindtime = 900\nport = 8443\nbanaction = iptables[name=ubiquiti, port=8443, protocol=tcp]' | sudo tee -a /etc/fail2ban/jail.local

# Restart Fail2ban to apply changes above.
sudo service fail2ban restart

# https://community.ubnt.com/t5/UniFi-Wireless/IMPORTANT-Debian-Ubuntu-users-MUST-READ-Updated-06-21/m-p/1968252#M233999
echo "JSVC_EXTRA_OPTS=\"\$JSVC_EXTRA_OPTS -Xss1280k\"" | sudo tee -a /etc/default/unifi

echo -e '\n\n\n  Ubiquiti UniFi Controller Install Complete...!'
echo '  Access controller by going to https://<SERVER_IP>:8443'
