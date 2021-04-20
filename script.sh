#!/bin/bash

DOMAIN=$(hostname)
php_install() {
    apt install software-properties-common -y
    add-apt-repository ppa:ondrej/php -y
    apt install php8.0 php8.0-fpm php8.0-mysql php8.0-opcache php8.0-cli -y
    a2enmod proxy_fcgi setenvif
    a2enconf php8.0-fpm
    systemctl enable php8.0-fpm && systemctl start php8.0-fpm
}
apache_install() {
    apt install apache2 apache2-utils -y
    systemctl enable apache2 && systemctl start apache2
    echo "ServerName localhost">>/etc/apache2/conf-available/servername.conf
    a2enconf servername.conf
    sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf
    sed -i 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' /etc/apache2/mods-available/dir.conf
    systemctl reload apache2
    mkdir /var/www/${DOMAIN}
    chown www-data:www-data /var/www/${DOMAIN} -R
    cat << _EOF_ > /etc/apache2/site-available/"${DOMAIN}".conf
<VirtualHost *:80>
    ServerName "${DOMAIN}"
    ServerAlias www."${DOMAIN}"
    ServerAdmin admin@"${DOMAIN}"
    
    DocumentRoot /var/www/"${DOMAIN}"
    
    ErrorLog "${APACHE_LOG_DIR}"/"${DOMAIN}"_error.log
    CustomLog "${APACHE_LOG_DIR}"/"${DOMAIN}"_access.log combined
</VirtualHost>
_EOF_
    a2ensite "${DOMAIN}".conf
    systemctl reload apache2
}
vhost() {
cat << _EOF_ > /var/www/"${DOMAIN}"/index.html
<!DOCTYPE html>
<html lang="en">
<html>
<head>
<!-- META TAGS -->
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="">
  <meta name="keywords" content="">
<!-- GOOGLE FONTS -->
  <link rel="preconnect" href="https://fonts.gstatic.com">
  <link href="https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,400;0,600;1,100&display=swap" rel="stylesheet">
<!-- FONT AWESOME -->
  <script src="https://kit.fontawesome.com/15db5bdf81.js" crossorigin="anonymous"></script>
<!-- W3 CSS -->
<link rel="stylesheet" href="https://www.w3schools.com/w3css/4/w3.css">
<title>"${DOMAIN}"</title>
</head>
<body>
<center><h2>Welcome to "${DOMAIN}"</h2></center>
<p>This page was generated automatically by the <a href="https://github.com/ryanc410/server-setup/script.sh">Server Setup Script</a></p>


</body>
</html>
_EOF_
}
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Run it as root..."
        sleep 2
        exit 3
    fi
}
check_root 
apt update && apt upgrade -y
apache_install
php_install
vhost
