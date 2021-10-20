#!/usr/bin/env bash
#----------------------------------------------------------------
## SCRIPT NAME: apachessl.sh
## AUTHOR: Ryan Cook
## DATE: 10/20/2021
## VERSION: 1.0
## DESCRIPTION: Automatically configures Apache with a Lets Encrypt SSL.
#----------------------------------------------------------------
## VARIABLES
#----------------------------------------------------------------
DOMAIN=
WEBROOT=/var/www/html
APACHE_LOG_DIR=/var/log/apache2
RETVAL="$?"
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
check_apache()
{
netstat -anp | grep apache | grep 80 &>/dev/null
    if [[ $RETVAL != 0 ]]; then
        echo "ERROR: Apache not found on system.."
        echo "Do you want to install it now?"
        read -r opt
        case "$opt" in
            y|Y|YES|yes|Yes)
                echo "Installing Apache Web Server.."
                apt install apache2 apache2-utils -y &>/dev/null
                systemctl enable apache2 &>/dev/null && systemctl start apache2 &>/dev/null
                ;;
            n|N|no|NO|No)
                echo "Script requires Apache to run. Exiting now.."
                sleep 2
                exit 0
                ;;
            *)
                usage
                ;;
        esac
    else
        echo "Updating Server.."
        apt update &>/dev/null && apt upgrade -y &>/dev/null
    fi
}



#----------------------------------------------------------------
## SCRIPT
#----------------------------------------------------------------

while [[ $# -gt 0 ]]
	do
 		case "$1" in
 			-d|--domain)
 				DOMAIN="$2"
 				shift
 				;;
 			--help|*)
				usage
 				;;
            --v|--version)
                echo "apachessl.sh V1.0"
                ;;
 		esac
 	shift
done

check_root

check_apache

if [[ -z $DOMAIN ]]; then
    DOMAIN=$(hostname -f)
fi

echo "Enabling Apache Modules.."
sleep 1
a2enmod ssl headers http2 &>/dev/null

echo "Installing Certbot.."
sleep 1
apt install certbot -y &>/dev/null

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
certbot certonly --agree-tos --non-interactive --email admin@"$DOMAIN" --webroot -w /var/lib/letsencrypt/ -d "$DOMAIN" -d www."$DOMAIN" &>/dev/null

if [[ $RETVAL != 0 ]]; then
    echo "ERROR: SSL Certificate could not be issued.."
    sleep 2
    exit 2
else
    echo "SSL Certificate has been issued for $DOMAIN!"
    sleep 2
fi

echo "Appending SSL Configuration in Virtual Host File.."
cat >> /etc/apache2/sites-available/"$DOMAIN".conf <<- _EOF_
<VirtualHost *:443>
    Protocols h2 http/1.1
    ServerName $DOMAIN

    DocumentRoot $WEBROOT

    ErrorLog ${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog ${APACHE_LOG_DIR}/$DOMAIN-access.log combined

    SSLEngine On
    SSLCertificateFile /etc/letsencrypt/live/$DOMAIN/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN/privkey.pem
</VirtualHost>
_EOF_

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
