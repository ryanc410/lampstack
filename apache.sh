#!/bin/bash
#####################################
# APACHE SERVER SETUP SCRIPT
#####################################
# Author: Ryan Cook
# https://github.com/ryanc410
# ryanhtown713@outlook.com
# 09/04/2021
#
#####################################
# FUNCTIONS
#####################################
help()
{
   clear
   echo "##################################################"
   echo "#     Apache Web Server Configuration Script     #"
   echo "##################################################"
   echo ""
   echo "USAGE: ./$0 -d {DOMAIN.COM}, -e {ADMIN_EMAIL@EMAIL.com}, -h, -i {111.111.1.111}, -p {8.0}, -s"
   echo ""
   echo "--OPTIONS--"
   echo ""
   echo "-d {DOMAIN.COM}              The -d option tells the script that {DOMAIN.COM} is what we are configuring this server for."
   echo ""
   echo "-e {ADMIN_EMAIL@EMAIL.COM}   -e Sets the admin email address for this server."
   echo ""
   echo "-h                           Prints this help menu"
   echo ""
   echo "-i {111.111.1.111}           The IP Address that resolves to the Domain Name you set with the -d option."
   echo ""
   echo "-p {8.0}                     The version of PHP you want installed. Options are 7.3, 7.4 and 8.0."
   echo ""
   echo "-s                           If -s is provided, the script will attempt to secure your domain with a Lets Encrypt SSL Cert."
   echo "                             YOU MUST HAVE THE APPROPRIATE DNS RECORDS SET FOR THIS OPTION TO WORK!"
   echo "                             A Record        @        IN        IP-ADDRESS-OF-SERVER"
   echo "                             A Record       www       IN        IP-ADDRESS-OF-SERVER"
   echo "                             *If these records are not set prior to running script the SSL Certificate will fail."
   echo ""
   sleep 15
}
check_root()
{
    if [[ $EUID -ne 0 ]]; then
        clear
        echo "Script must be ran as the root user."
        sleep 2
        exit 1
    fi
}
ssl_install()
{
    apt install certbot -y 

    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 
    mkdir -p /var/lib/letsencrypt/.well-known 
    chgrp www-data /var/lib/letsencrypt 
    chmod g+s /var/lib/letsencrypt 

    cat << _EOF_ >>/etc/apache2/conf-available/letsencrypt.conf 
Alias /.well-known/acme-challenge/ "/var/lib/letsencrypt/.well-known/acme-challenge/"
<Directory "/var/lib/letsencrypt/">
    AllowOverride None
    Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
    Require method GET POST OPTIONS
</Directory>
_EOF_

    cat << _EOF_ >>/etc/apache2/conf-available/ssl-params.conf 
SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite          ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder     off
SSLSessionTickets       off

SSLUseStapling On
SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"

SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem" 

Header always set Strict-Transport-Security "max-age=63072000"
_EOF_

    a2enmod ssl headers http2 
    a2enconf letsencrypt ssl-params 

    systemctl reload apache2 

    certbot certonly --agree-tos --non-interactive --email $admin_email --webroot -w /var/lib/letsencrypt/ -d $domain -d www.$domain 

cat << _EOF_ >>/etc/apache2/sites-available/$domain.conf 
<VirtualHost $ip:443>
  ServerName $domain

  Protocols h2 http/1.1

  <If "%{HTTP_HOST} == 'www.$domain'">
    Redirect permanent / https://$domain/
  </If>

  DocumentRoot /var/www/$domain
  ErrorLog /var/log/apache2/$domain-error.log
  CustomLog /var/log/apache2/$domain-access.log combined

  SSLEngine On
  SSLCertificateFile /etc/letsencrypt/live/$domain/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem
</VirtualHost>
_EOF_
}
header()
{
    clear
    echo "##################################################"
    echo "#     Apache Web Server Configuration Script     #"
    echo "##################################################"
    echo ""
}

#####################################
# SCRIPT
#####################################

while getopts ":hd:i:e:p:s" option; do
    case ${option} in
        h)
            help
            exit
            ;;
        d)
            domain=${OPTARG}
            ;;
        i)
            ip=${OPTARG}
            ;;
        e)
            admin_email=${OPTARG}
            ;;
        p)
            php_ver=${OPTARG}
            ;;
        s)
            ssl=TRUE
            ;;
        :)
            clear
            echo "ERROR: -${OPTARG} requires an argument."
            sleep 3
            exit 2
            ;;
   esac
done

# Checks to make sure script is ran with root privileges
check_root

header


apt update && apt upgrade -y 


apt install apache2 apache2-utils -y 


systemctl enable apache2 && systemctl start apache2 


echo "ServerName localhost">>/etc/apache2/conf-available/servername.conf 
a2enconf servername.conf 

systemctl reload apache2 


cat << _EOF_ >>/etc/apache2/sites-available/$domain.conf 
<VirtualHost $ip:80>
    ServerName $domain
    ServerAlias www.$domain
    ServerAdmin $admin_email

    DocumentRoot /var/www/$domain

    ErrorLog ${APACHE_LOG_DIR}/$domain-error.log
    CustomLog ${APACHE_LOG_DIR}/$domain-access.log combined
</VirtualHost>
_EOF_


a2ensite $domain.conF 
a2dissite 000-default.conf 

systemctl reload apache2 


mkdir -p /var/www/$domain 
chown www-data:www-data /var/www/$domain -R 

sed -i 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' /etc/apache2/mods-enabled/dir.conf 


cat << _EOF_ > /var/www/$domain/index.html 
<!DOCTYPE html>
<html lang="en">
<head>
  <title>$domain</title>
</head>
<body style="background-color: #000000;">
<center><h2 style="color: #ffffff;">Apache is Working!</h2></center>
<br>
<br>
<center><h4 style="color: #ffffff;">This Web server was configured automatically using the Apache Web Server Install Script</h4></center>
<center><p style="color: #ffffff;">git clone https://github.com/ryanc410/server-setup.git <strong>Clone the Repository</strong></p></center>
<center><p style="color: #ffffff;">chmod +x apache.sh <strong>Make executable</strong></p></center>
<center><p style="color: #ffffff;">./apache.sh <strong>Run the script</strong></p></center>
</body>
</html>
_EOF_

sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf 


if [[ $php_ver == "8.0" ]]; then
    apt install software-properties-common -y 
    add-apt-repository ppa:ondrej/php -y 
    apt update $quiet
fi
apt install php$php_ver php$php_ver-cli php$php_ver-fpm php$php_ver-mysql -y 

a2enmod proxy_fcgi setenvif 
a2dismod php$php_ver 
a2enconf php$php_ver-fpm 


systemctl enable php$php_ver-fpm && systemctl start php$php_ver-fpm 

systemctl reload apache2 && systemctl reload php$php_ver-fpm 

if [[ $ssl == "TRUE" ]]; then
    ssl_install
fi
