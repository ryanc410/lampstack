#!/bin/bash
#####################################
# APACHE SERVER SETUP SCRIPT
#####################################
#
#
#
#####################################
# VARIABLES
#####################################
#pub_ip=$(curl ifconfig.me.)

# SET VARIABLES BELOW THIS LINE ONLY!
domain=
ip=
admin_email=
web_root=
php_ver=
php_memory_limit=
php_max_upload_size=
mysql_user=
mysql_user_pass=
timezone=
ssl=

#####################################
# FUNCTIONS
#####################################
help()
{
   clear
   echo "##################################################"
   echo "#     Apache Web Server Configuration Script     #"
   echo "##################################################"
   echo
   echo "USAGE: apache.sh [-h]"
   echo ""
   echo "HOW TO USE SCRIPT"
   echo ""
   echo "1. Open the setup.sh file in nano or your preferred text editor."
   echo "2. Fill in the variables with how you want the server to be configured."
   echo "3. Save and exit."
   echo "4. Run command: chmod +x setup.sh"
   echo "5. If you opted Y for the ssl variable, make sure you have the appropriate DNS records set for your domain:"
   echo " A Record        @        IN        IP-ADDRESS-OF-SERVER"
   echo " A Record       www       IN        IP-ADDRESS-OF-SERVER"
   echo "*If these records are not set prior to running script the SSL Certificate will fail."
   echo ""
   echo "--Variable Examples--"
   echo ""
   echo "domain=example.com"
   echo ""
   echo "ip=000.00.0.000 (which points to example.com in your dns records)"
   echo ""
   echo "admin_email=admin@example.com"
   echo ""
   echo "web_root=/var/www/html/example.com"
   echo ""
   echo "php_ver=(7.3),(7.4),(8.0) Earlier versions are no longer supported."
   echo ""
   echo "php_memory_limit=(256M),(512M)"
   echo ""
   echo "php_max_upload_size=100M"
   echo ""
   echo "mysql_user=bob A user that you will use for php database connections"
   echo ""
   echo "mysql_user_pass=bobs-password"
   echo ""
   echo "timezone=America/Chicago"
   echo ""
   echo "ssl=(Y),(N) If set to Y, a lets encrypt certificate will be installed for the specified domain."
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
check_vars()
{
    if [[ $domain == "" ]]; then
        clear
        echo "You must set the domain variable."
        sleep 2
        exit 2
    elif [[ $ip == "" ]]; then
        clear
        echo "You must set the ip variable."
        sleep 2
        exit 2
    elif [[ $admin_email == "" ]]; then
        clear
        echo "You must set the admin_email variable."
        sleep 2
        exit 2
    elif [[ $web_root == "" ]]; then
        clear
        echo "You must set the web_root variable."
        sleep 2
        exit 2
    elif [[ $php_ver == "" ]]; then
        clear
        echo "You must set the php_ver variable."
        sleep 2
        exit 2
    elif [[ $timezone == "" ]]; then
        clear
        echo "You must set the timezone variable."
        sleep 2
        exit 2
    elif [[ $ssl == "" ]]; then
        clear
        echo "You must set the ssl variable."
        exit 2
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

  DocumentRoot $web_root
  ErrorLog /var/log/apache2/$domain-error.log
  CustomLog /var/log/apache2/$domain-access.log combined

  SSLEngine On
  SSLCertificateFile /etc/letsencrypt/live/$domain/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/$domain/privkey.pem
</VirtualHost>
_EOF_
}

#####################################
# SCRIPT
#####################################

while getopts ":h" option; do
   case $option in
      h)
         help
         exit;;
   esac
done

check_root

check_vars

apt update 

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

    DocumentRoot $web_root

    ErrorLog /var/log/apache2/$domain-error.log
    CustomLog /var/log/apache2/$domain-access.log combined
</VirtualHost>
_EOF_

a2ensite $domain.conf
a2dissite 000-default.conf

systemctl reload apache2

mkdir -p $web_root
chown www-data:www-data $web_root -R

cat << _EOF_ >>$web_root/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <title></title>
</head>
<body style="background-color: #000000;">
<center><h2 style="color: #ffffff;">Apache is Working!</h2></center>
<br>
<br>
<center><h4 style="color: #ffffff;">This Web server was configured automatically using the Apache Web Server Install Script</h4></center>
<center><p style="color: #ffffff;">git clone https://github.com/ryanc410/server-setup.git <strong>Clone the Repository</strong></p></center>
<center><p style="color: #ffffff;">nano apache.sh <strong>Set the variables</strong></p>
<center><p style="color: #ffffff;">chmod +x apache.sh <strong>Make executable</strong></p></center>
<center><p style="color: #ffffff;">./apache.sh <strong>Run the script</strong></p></center>
</body>
</html>
_EOF_

sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf

apt install php$php_ver php$php_ver-cli php$php_ver-fpm php$php_ver-mysql -y

a2enmod proxy_fcgi setenvif
a2dismod php$php_ver
a2enconf php$php_ver-fpm

systemctl enable php$php_ver-fpm && systemctl start php$php_ver-fpm

sed -i "s/memory_limit = 128M/memory_limit = $php_memory_limit/g" /etc/php/$php_ver/fpm/php.ini
sed -i "s/memory_limit = 128M/memory_limit = $php_memory_limit/g" /etc/php/$php_ver/cli/php.ini

sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $php_max_upload_size/g" /etc/php/$php_ver/fpm/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $php_max_upload_size/g" /etc/php/$php_ver/cli/php.ini

sed -i "s|;date.timezone =|date.timezone = $timezone|g" /etc/php/$php_ver/fpm/php.ini
sed -i "s|;date.timezone =|date.timezone = $timezone|g" /etc/php/$php_ver/cli/php.ini

sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/$php_ver/fpm/php.ini
sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/$php_ver/cli/php.ini

sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/$php_ver/fpm/php.ini
sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/$php_ver/cli/php.ini

sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/$php_ver/fpm/php.ini
sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/$php_ver/cli/php.ini

sed -i "s/mysqli.default_user =/mysqli.default_user = $mysql_user/g" /etc/php/$php_ver/fpm/php.ini
sed -i "s/mysqli.default_user =/mysqli.default_user = $mysql_user/g" /etc/php/$php_ver/cli/php.ini

sed -i "s/mysqli.default_pw =/mysqli.default_pw = $mysql_user_pass/g" /etc/php/$php_ver/fpm/php.ini
sed -i "s/mysqli.default_pw =/mysqli.default_pw = $mysql_user_pass/g" /etc/php/$php_ver/cli/php.ini

systemctl reload apache2 && systemctl reload php$php_ver-fpm

if [[ $ssl == "Y" ]]; then
    ssl_install
fi

