#!/usr/bin/env bash
#----------------------------------------------
# SCRIPT: https://github.com/ryanc410/server-setup/apache.sh
# AUTHOR: Ryan Cook 
# DATE: 10/18/2021
# VERSION: 2.0
#DESCRIPTION: Configure the Apache Web Server
#----------------------------------------------
# VARIABLES
#----------------------------------------------
DOMAIN=$(hostname -f)
IP_ADDRESS=
WEBROOT=/var/www/"$DOMAIN"
APACHE_LOG_DIR=/var/log/apache2
#----------------------------------------------
# FUNCTIONS
#----------------------------------------------
usage()
{
    clear
echo "Script configures Apache with a foundation for web development."
echo
echo "Syntax: apache.sh [OPTIONS] [ARGS..]"
echo "OPTIONS:"
echo "-d|--domain example.com				Set the Domain for the Virtual Host."
echo "-i|--ip 000.000.000.000 				Set the IP Address for the Virtual Host."
echo "-w|--webroot /example/webroot/dir		Set the webroot directory for the Virtual Host."
echo "-v|--version							Print software version and exit."
echo "-h|--help"
echo
}
checkroot()
{
    if [[ $EUID != 0 ]]; then
        echo "ERROR: Script must be executed with root privileges!"
        sleep 3
        exit 1
    fi
}
checkos()
{
    if [[ $OSTYPE != linux-gnu ]]; then
        echo "ERROR: Operating System not compatible with script!"
        sleep 3
        exit 2
    fi
}
#----------------------------------------------
# SCRIPT
#----------------------------------------------

while [[ $# > 0 ]]
	do
 		case "$1" in
 			-d|--domain)
 				DOMAIN="$2"
 				shift
 				;;
 			-i|--ip)
 				IP_ADDRESS="$2"
 				shift
 				;;
 			-w|--webroot)
 				WEBROOT="$2"
 				shift
 				;;
 			--help|*)
				usage
 				;;
 		esac
 	shift
done

checkroot

checkos

echo "Updating repositories and upgrading packages..."
apt update &>/dev/null && apt upgrade -y &>/dev/null  

echo "Installing apache..."
apt install apache2 apache2-utils -y &>/dev/null

echo "Starting apache..."
systemctl enable apache2 &>/dev/null && systemctl start apache2 &>/dev/null

echo "Creating new webroot directory..."
mkdir -p "$WEBROOT" &>/dev/null

echo "Copying index.html to new webroot directory..."
cp /var/www/html/index.html "$WEBROOT"/

echo "Setting permissions for webroot directory..."
chown www-data:www-data "$WEBROOT" -R &>/dev/null

echo "Setting web root directory options in apache.conf..."
cat >> /etc/apache2/apache2.conf <<- _EOF_
<Directory $WEBROOT>
    Options FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
_EOF_

echo "Creating servername configuration file..."
echo "ServerName localhost" /etc/apache2/conf-available/servername.conf &>/dev/null

echo "Enabling servername.conf..."
a2enconf servername.conf &>/dev/null

echo "Checking variables..."
if [[ -z $IP_ADDRESS ]]; then
    IP_ADDRESS=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
elif [[ -z $DOMAIN ]]; then
    DOMAIN=$(hostname -f)
elif [[ -z $WEBROOT ]]; then
    WEBROOT=/var/www/"$DOMAIN"
fi

echo "Creating new virtual host file..."
cat > /etc/apache2/sites-available/"$DOMAIN".conf <<- _EOF_
<VirtualHost $IP_ADDRESS:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN

    ServerAdmin admin@$DOMAIN

    DocumentRoot $WEBROOT

    ErrorLog $APACHE_LOG_DIR/$DOMAIN-error.log
    CustomLog $APACHE_LOG_DIR/$DOMAIN-access.log combined
</VirtualHost>
_EOF_

echo "Disabling default virtual host..."
a2dissite 000-default.conf &>/dev/null

echo "Enabling new virtual host..."
a2ensite "$DOMAIN".conf &>/dev/null

echo "Restarting Apache Web Server..."
systemctl restart apache2 &>/dev/null

apachectl -t &>/dev/null

if [[ $? = 0 ]]; then
    echo "Apache was configured successfully! View your site at $DOMAIN."
    sleep 3
    exit 0
else
    echo "There was a problem configuring apache..."
    sleep 3
    exit 3
fi
