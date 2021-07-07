#!/bin/bash

DOMAIN=$(hostname -f)
IP=$(curl ifconfig.me.)

check_root()
{
    if [[ $EUID -ne 0 ]];then
        clear
        echo "Run the script as root"
        sleep 2
        exit 1
    fi
}
install_apps()
{
    apt install apache2 apache2-utils php php-fpm php-mysql php-cli mysql-server curl -y
}

check_root

apt update 

install_apps

echo "ServerName localhost">>/etc/apache2/conf-available/servername.conf
a2enconf servername.conf

a2enmod proxy_fcgi setenvif
a2dismod php7.4
a2enconf php7.4-fpm
systemctl reload apache2

systemctl enable apache2 && systemctl start apache2

systemctl enable php7.4-fpm && systemctl start php7.4-fpm

systemctl enable mysql && systemctl start mysql

cat << _EOF_ >> /etc/apache2/sites-available/${DOMAIN}.conf
<VirtualHost $IP:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN

    DocumentRoot /var/www/html/$DOMAIN

    ErrorLog /var/log/apache2/$DOMAIN-error.log
    CustomLog /var/log/apache2/$DOMAIN-access.log combined
</VirtualHost>
_EOF_

a2ensite ${DOMAIN}.conf
a2dissite 000-default.conf

sed -i 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' /etc/apache2/mods-available/dir.conf

sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf

systemctl reload apache2
