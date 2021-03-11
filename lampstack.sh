#!/bin/bash

# If your not root exit
if [[ $EUID -ne 0 ]]; then
    echo "Must be root to run this script."
    sleep 3
    exit 3
fi

# Update repositories and upgrade packages
apt update && sudo apt upgrade -y

# Check to see if apache2 is already installed and if not install it
command -v apache2 2> /dev/null
if [[ $? -ne 0 ]]; then 
    apt install apache2 apache2-utils -y
    systemctl start apache2 && systemctl enable apache2
fi

# Check if iptables is installed and if so open ports for apache2
command -v iptables 2> /dev/null
    if [[ $? -eq 0 ]]; then
        iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    fi

# Check if UFW is installed and if so Open ports for apache2
command -v ufw 2> /dev/null
    if [[ $? -eq 0 ]]; then
        ufw allow http
    fi

# Change ownership of web root directory
chown www-data:www-data /var/www/html/ -R

# Create servername.conf to suppress warning about fqdn
echo "ServerName localhost">>/etc/apache2/conf-available/servername.conf
a2enconf servername.conf
systemctl reload apache2

# Check to see if mariadb is already installed
command -v mariadb-server 2> /dev/null
    if [[ $? -ne 0 ]]; then
        apt install mariadb-server mariadb-client -y
    fi

# Start and enable mariadb on boot
systemctl start mariadb && systemctl enable mariadb

# Check if PHP7.4 is already installed
command -v php7.4 2> /dev/null
    if [[ $? -ne 0 ]]; then
        apt install php7.4 libapache2-mod-php7.4 php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline -y
    fi

# Disable php7.4.conf
a2dismod php7.4

apt install php7.4-fpm -y

a2enmod proxy_fcgi setenvif

# Enable php-fpm in Apache
a2enconf php7.4-fpm
systemctl restart apache2

# Secure The Database
mysql_secure_installation
