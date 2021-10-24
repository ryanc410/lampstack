#!/usr/bin/env bash
#******************************************************************
## SCRIPT NAME: php-setup.sh
## AUTHOR: Ryan Cook
## DATE: 10/24/2021
## DESCRIPTION: Installs and configures PHP
#******************************************************************
## VARIABLES
#******************************************************************
PHP_VERSION=
TIME_ZONE=
INCLUDE_DIR=
RETVAL=$?
#******************************************************************
## FUNCTIONS
#******************************************************************
check_root()
{
    if [[ $EUID != 0 ]]; then
        echo "ERROR: Script needs root privileges to run..."
        sleep 3
        exit 1
    fi
}
check_os()
{
    if [[ $OSTYPE != linux-gnu ]]; then
        echo "ERROR: Script not compatible with your Operating System..."
        sleep 3
        exit 2
    fi
}
install_ppa()
{
    add-apt-repository ppa:ondrej/php -y >/dev/null
    apt update >/dev/null
}
config_php()
{
    # Set Timezone
    sed -i "s|;date.timezone =|date.timezone = $TIME_ZONE|g" /etc/php/"$PHP_VERSION"/fpm/php.ini
    sed -i "s|;date.timezone =|date.timezone = $TIME_ZONE|g" /etc/php/"$PHP_VERSION"/cli/php.ini
    sed -i "s|;date.timezone =|date.timezone = $TIME_ZONE|g" /etc/php/"$PHP_VERSION"/apache2/php.ini
    # Set Sendmail Path
    sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/"$PHP_VERSION"/fpm/php.ini
    sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/"$PHP_VERSION"/cli/php.ini
    sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/"$PHP_VERSION"/apache2/php.ini
    # Set Default Mysql Socket
    sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/"$PHP_VERSION"/fpm/php.ini
    sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/"$PHP_VERSION"/cli/php.ini
    sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/"$PHP_VERSION"/apache2/php.ini
    # Set Default Mysql Host
    sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/"$PHP_VERSION"/fpm/php.ini
    sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/"$PHP_VERSION"/cli/php.ini
    sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/"$PHP_VERSION"/apache2/php.ini
    # Set Include Directory
    sed -i "s|;include_path = ".:/usr/share/php"|include_path = $INCLUDE_DIR|g" /etc/php/"$PHP_VERSION"/fpm/php.ini
    sed -i "s|;include_path = ".:/usr/share/php"|include_path = $INCLUDE_DIR|g" /etc/php/"$PHP_VERSION"/cli/php.ini
    sed -i "s|;include_path = ".:/usr/share/php"|include_path = $INCLUDE_DIR|g" /etc/php/"$PHP_VERSION"/apache2/php.ini
}
check_version()
{
    case "$PHP_VERSION" in
    8.0|8)
        PHP_VERSION=8.0
        ;;
    7.4)
        PHP_VERSION=7.4
        ;;
    7.3)
        PHP_VERSION=7.3
        ;;
    *)
        echo "ERROR: You entered a version number not supported by this script."
        sleep 2
        exit 3
        ;;
esac
}
#******************************************************************
## SCRIPT
#******************************************************************

check_root && check_os

case "$1" in
	-v|--version)
        PHP_VERSION="$2"
        check_version
        shift
        ;;
    -t|--timezone)
        TIME_ZONE="$2"
        shift
        ;;
    -?|--help)
		help_menu
		;;
	*)
	  echo "ERROR: Unrecognized argument"
	  sleep 2
	  exit 5
	  ;;
esac

if [[ -z $PHP_VERSION ]]; then
    PHP_VERSION=8.0
elif [[ -z $INCLUDE_DIR ]]; then
    INCLUDE_DIR=/etc/php/includes
elif [[ -z $TIME_ZONE ]]; then
    TIME_ZONE=UTC
fi

echo "Updating server packages..."
apt update >/dev/null && apt upgrade -y >/dev/null

echo "Installing required packages..."
apt install software-properties-common -y >/dev/null

echo "Installing PHP PPA..."
install_ppa

echo "Installing PHP and PHP modules..."
apt install php"$PHP_VERSION"-{fpm,cli,xml,curl,opcache,mbstring,intl,gd,mysql,zip} libapache2-mod-php"$PHP_VERSION" -y >/dev/null

config_php

apachectl -t >/dev/null
if [[ $RETVAL = 0 ]]; then
    echo "Enabling Apache modules for PHP-fpm..."
    a2enmod proxy_fcgi setenvif >/dev/null
    a2enconf php"$PHP_VERSION"-fpm >/dev/null
fi

echo "Enabling PHP-FPM to run at system boot..."
systemctl enable php"$PHP_VERSION"-fpm >/dev/null && systemctl start php"$PHP_VERSION"-fpm >/dev/null

systemctl status php"$PHP_VERSION"-fpm >/dev/null
if [[ $RETVAL = 0 ]]; then
    echo "PHP has been configured successfully!"
    sleep 3
    exit 0
else
    echo "ERROR: There was a problem installing PHP..."
    sleep 3
    exit 1
fi

systemctl reload apache2 && systemctl reload php*.*-fpm
echo "Script Complete"
