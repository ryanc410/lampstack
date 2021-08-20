#!/bin/bash
#
#
#
#
#####################################
# VARIABLES
#####################################

mem_limit=
upload_size=
tz=
mysql_user=
mysql_user_pass=

#####################################
# FUNCTIONS
#####################################

help()
{
   clear
   echo "##############################################"
   echo "#        PHP.INI Configuration Script        #"            
   echo "##############################################"
   echo
   echo "Author: Ryan Cook"
   echo "Date Modified: 07/12/2021"
   echo 
   echo "Before Running the script, you must set the variables to values that reflect how you want PHP to be configured."
   echo 
   echo "Examples:"
   echo 
   echo "mem_limit= This value represents the memory limit that is allocated to PHP scripts.Correct values can be 128M, 512M.. etc."
   echo "upload_size= This value is the allowed size of a file to be uploaded using PHP."
   echo "tz= This is your timezone. Format is America/Chicago."
   echo "mysql_user= This is a user that you will use for database connections using php."
   echo "mysql_user_pass= The password for the mysql user used for database connections using php."
   echo
}
check_root()
{
    if [[ $EUID -ne 0 ]]; then
        clear
        echo "Script must be ran with root privileges.."
        sleep 2
        exit 1
    fi
}
check_mods()
{
    clear
    echo "Checking for Apache2 PHP module.."
    sleep 1
    dpkg --list | grep libapache2-mod-php*.* &>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Module not found, Installing now.."
            sleep 1
            apt install libapache2-mod-php -y &>/dev/null
            echo "Module Installed.."
            sleep 1
        fi
    
    echo "Checking for PHP-FPM module.."
    sleep 1
    dpkg --list | grep php*.*-fpm &>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Module not found, Installing now.."
            sleep 1
            apt install php-fpm -y &>/dev/null
            echo "Module Installed.."
            sleep 1
        fi
    echo "Checking for PHP-CLI module.."
    sleep 1    
    dpkg --list | grep php*.*-cli &>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Module not found, Installing now.."
            sleep 1
            apt install php-cli -y &>/dev/null
            echo "Module Installed.."
            sleep 1
        fi
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

check_mods

command -v mysql &>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "Mysql Server not installed. Installing now.."
        sleep 1
        apt install mysql-server -y &>/dev/null
        echo "Mysql Server Installed."
        sleep 1
    fi


sed -i "s/memory_limit = 128M/memory_limit = $mem_limit/g" /etc/php/7.4/fpm/php.ini
sed -i "s/memory_limit = 128M/memory_limit = $mem_limit/g" /etc/php/7.4/cli/php.ini
sed -i "s/memory_limit = 128M/memory_limit = $mem_limit/g" /etc/php/7.4/apache2/php.ini

sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $upload_size/g" /etc/php/7.4/fpm/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $upload_size/g" /etc/php/7.4/cli/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $upload_size/g" /etc/php/7.4/apache2/php.ini

sed -i "s|;date.timezone =|date.timezone = $tz|g" /etc/php/7.4/fpm/php.ini
sed -i "s|;date.timezone =|date.timezone = $tz|g" /etc/php/7.4/cli/php.ini
sed -i "s|;date.timezone =|date.timezone = $tz|g" /etc/php/7.4/apache2/php.ini

sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/7.4/fpm/php.ini
sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/7.4/cli/php.ini
sed -i 's|;sendmail_path =|sendmail_path = /usr/sbin/sendmail|g' /etc/php/7.4/apache2/php.ini

sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/7.4/fpm/php.ini
sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/7.4/cli/php.ini
sed -i 's|mysqli.default_socket =|mysqli.default_socket = /var/run/mysqld/mysqld.sock|g' /etc/php/7.4/apache2/php.ini

sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/7.4/fpm/php.ini
sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/7.4/cli/php.ini
sed -i 's/mysqli.default_host =/mysqli.default_host = localhost/g' /etc/php/7.4/apache2/php.ini

sed -i "s/mysqli.default_user =/mysqli.default_user = $mysql_user/g" /etc/php/7.4/fpm/php.ini
sed -i "s/mysqli.default_user =/mysqli.default_user = $mysql_user/g" /etc/php/7.4/cli/php.ini
sed -i "s/mysqli.default_user =/mysqli.default_user = $mysql_user/g" /etc/php/7.4/apache2/php.ini

sed -i "s/mysqli.default_pw =/mysqli.default_pw = $mysql_user_pass/g" /etc/php/7.4/fpm/php.ini
sed -i "s/mysqli.default_pw =/mysqli.default_pw = $mysql_user_pass/g" /etc/php/7.4/cli/php.ini
sed -i "s/mysqli.default_pw =/mysqli.default_pw = $mysql_user_pass/g" /etc/php/7.4/apache2/php.ini

systemctl reload apache2 && systemctl reload php*.*-fpm
echo "Script Complete"
