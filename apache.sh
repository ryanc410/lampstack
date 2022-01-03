#!/usr/bin/env bash
#----------------------------------------------#
# https://github.com/ryanc410/server-setup.git #
# DATE: 10/18/2021                             #
# VERSION: 2.1                                 #
#----------------------------------------------#
# FUNCTIONS                                 #
#-------------------------------------------#
function usage()
{
echo "One click Apache Web Server configuration."
echo
echo "Syntax: apache.sh [OPTIONS] [ARGS..]"
echo "OPTIONS:"
echo "-d|--domain example.com               Set the Domain for the Virtual Host."
echo "-s|--ssl                              Configure a Lets Encrypt SSL Certificate for Apache."
echo "-v|--version                          Print software version and exit."
echo "-h|--help"
echo
}
#-------------------------------------------#
# SCRIPT                                    #
#-------------------------------------------#
if [[ $EUID != 0 ]]; then
    echo "Must be root to run this script!"
    sleep 2
    exit 1
fi

while [[ $# != "" ]]
do
case "$1" in
    -d | --domain )
        shift
        domain="$1"
        ;;
    -s | -ssl )
        ssl=true
        shift
        ;;
    -v | --version )
        echo "apache.sh v2.0"
        sleep 2
        exit
        ;;
    -h | --help )
        clear
        usage
        exit
        ;;
esac
done

apt update 
apt upgrade -y
apt install apache2 apache2-utils -y
systemctl start apache2
systemctl enable apache2
cat >> /etc/apache2/conf-available/servername.conf << _EOF_
ServerName localhost
_EOF_
a2enconf servername.conf
chown www-data:www-data /var/www/html -R
a2dissite 000-default.conf
sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf
cat >> /etc/apache2/sites-available/"$domain".conf <<- _EOF_
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain

    DocumentRoot /var/www/html

    ErrorLog '${APACHE_LOG_DIR}'/$domain-error.log
    CustomLog '${APACHE_LOG_DIR}'/$domain-access.log combined
</VirtualHost>
_EOF_
a2ensite "$domain".conf
systemctl reload apache2
apache2ctl -t
if [[ $? = 0 ]]; then
    echo "Apache was configured successfully!"
    sleep 3
else
    echo "There was a problem configuring Apache.."
    sleep 3
    exit 1
fi
if [[ $ssl = true ]]; then
    apt install certbot -y
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    mkdir -p /var/lib/letsencrypt/.well-known
    chgrp www-data /var/lib/letsencrypt
    chmod g+s /var/lib/letsencrypt
    cat >> /etc/apache2/conf-available/letsencrypt.conf <<- _EOF_
Alias /.well-known/acme-challenge/ "/var/lib/letsencrypt/.well-known/acme-challenge/"
<Directory "/var/lib/letsencrypt/">
    AllowOverride None
    Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
    Require method GET POST OPTIONS
</Directory>
_EOF_
    cat >> /etc/apache2/conf-available/ssl-params.conf <<- _EOF_
SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder     off
SSLSessionTickets       off

SSLUseStapling On
SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"

Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set X-Frame-Options SAMEORIGIN
Header always set X-Content-Type-Options nosniff

SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"
_EOF_
    a2enmod ssl headers http2
    a2enconf ssl-params letsencrypt
    systemctl reload apache2
    certbot certonly --agree-tos --email admin@"$domain" --webroot -w /var/lib/letsencrypt/ -d "$domain" -d www."$domain"
    cat >> /etc/apache2/sites-available/"$domain"-ssl.conf <<- _EOF_
<VirtualHost *:443>
  ServerName $domain
  ServerAlias www.$domain

  Protocols h2 http/1.1

  <If "%{HTTP_HOST} == 'www.$domain'">
    Redirect permanent / https://$domain/
  </If>

  DocumentRoot /var/www/html
  ErrorLog '${APACHE_LOG_DIR}'/$domain-error.log
  CustomLog '${APACHE_LOG_DIR}'/$domain-access.log combined

  SSLEngine On
  SSLCertificateFile /etc/letsencrypt/live/$domain/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem
</VirtualHost>
_EOF_
    a2ensite "$domain"-ssl.conf
    systemctl reload apache2
    apache2ctl -t
    if [[ $? = 0 ]]; then
        echo "Script completed Successfully!"
        sleep 3
        exit 0
    else
        echo "Script could not configure SSL for $domain.."
        sleep 3
        exit 1
    fi
fi
