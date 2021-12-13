#!/usr/bin/env bash
#----------------------------------------------------------------
## SCRIPT NAME: apachessl.sh
## AUTHOR: Ryan Cook
## DATE: 10/20/2021
## VERSION: 2.0
## DESCRIPTION: Automatically configures Apache with a Lets Encrypt SSL.
#----------------------------------------------------------------
## VARIABLES
#----------------------------------------------------------------
domain=
APACHE_LOG_DIR=/var/log/apache2
retval="$?"
#----------------------------------------------------------------
## FUNCTIONS
#----------------------------------------------------------------
usage()
{
clear
echo "apachessl.sh - Automatically configure a Lets Encrypt SSL for your Domain"
echo ""
echo "Syntax: ./apachessl.sh [OPTIONS] [ARGS..]"
echo ""
echo "Options"
echo ""
echo "-d|--domain       Set the Domain you want to request a SSL Cert for."
echo "-h|--help         Show Usage Options."
echo "-v|--version      Print version number."
echo ""
}
check_root()
{
if [[ $EUID != 0 ]]; then
    echo "ERROR: Need root privileges for this script to run.."
    sleep 2
    exit 1
fi
}

#----------------------------------------------------------------
## SCRIPT
#----------------------------------------------------------------
while [[ $# -gt 0 ]]
	do
 		case "$1" in
 			-d|--domain)
 				domain="$2"
 				shift
 				;;
 			--help|*)
				usage
 				;;
            --v|--version)
                echo "apachessl.sh V2.0"
                ;;
 		esac
 	shift
done

check_root

echo "Checking Apache Web Server is installed.."
sleep 1
netstat -anp | grep apache | grep 80 &>/dev/null
if [[ $retval != 0 ]]; then
    echo "ERROR: This script needs the Apache Web Server to function."
    sleep 3
    exit 1
fi

if [[ -z $domain ]]; then
    echo "No Domain was specified on execution."
    sleep 3
    exit 1
fi

echo "Enabling Apache Modules.."
sleep 1
a2enmod ssl headers http2

echo "Installing Certbot.."
sleep 1
apt install certbot -y

echo "Generating Diffie Helman.."
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 &>/dev/null

echo "Creating directories for Lets Encrypt.."
sleep 1
mkdir -p /var/lib/letsencrypt/.well-known &>/dev/null
chgrp www-data /var/lib/letsencrypt &>/dev/null
chmod g+s /var/lib/letsencrypt &>/dev/null

echo "Creating letsencrypt.conf.."
sleep 1
cat > /etc/apache2/conf-available/letsencrypt.conf <<- _EOF_
Alias /.well-known/acme-challenge/ "/var/lib/letsencrypt/.well-known/acme-challenge/"
<Directory "/var/lib/letsencrypt/">
    AllowOverride None
    Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
	Require method GET POST OPTIONS
</Directory>
_EOF_

echo "Creating ssl-params.conf.."
sleep 1
cat > /etc/apache2/conf-available/ssl-params.conf <<- _EOF_
SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder     off
SSLSessionTickets       off
SSLUseStapling On
SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"
SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"
Header always set Strict-Transport-Security "max-age=63072000"
_EOF_

echo "Enabling newly created configuration files.."
sleep 1
a2enconf letsencrypt ssl-params &>/dev/null

echo "Reloading Apache.."
sleep 1
systemctl reload apache2 &>/dev/null

echo "Requesting SSL Certificate.."
sleep 1
certbot certonly --agree-tos --non-interactive --email admin@"$domain" --webroot -w /var/lib/letsencrypt/ -d "$domain" -d www."$domain" &>/dev/null

if [[ $RETVAL != 0 ]]; then
    echo "ERROR: SSL Certificate could not be issued.."
    sleep 2
    exit 2
else
    echo "SSL Certificate has been issued for $DOMAIN!"
    sleep 2
fi

echo "Creating SSL Virtual Host file.."
cat > /etc/apache2/sites-available/"$domain"-ssl.conf <<- _EOF_
<VirtualHost *:443>
    Protocols h2 http/1.1
    ServerName $domain
    DocumentRoot /var/www/$domain
    ErrorLog ${APACHE_LOG_DIR}/$domain-error.log
    CustomLog ${APACHE_LOG_DIR}/$domain-access.log combined
    SSLEngine On
    SSLCertificateFile /etc/letsencrypt/live/$domain/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem
</VirtualHost>
_EOF_

echo "Enabling new virtual host.."
sleep 1
a2ensite "$domain"-ssl.conf

echo "Restarting Apache to load new configuration.."
sleep 1
systemctl reload apache2 &>/dev/null

if [[ $RETVAL = 0 ]]; then
    echo "SSL successfully configured for $DOMAIN!"
    sleep 2
    echo "Script Exiting.."
    exit 0
else
    echo "ERROR: Something went wrong with Apache.."
    sleep 2
    exit 3
fi
