#!/bin/bash
#
# Author: Ryan Cook
# Date: 08/24/2021
# Description: Install Mysql server and phpmyadmin

# VARIABLES
#########################################
MYSQL_USER=
MYSQL_USER_PW=
MYSQL_ROOT_PW=


# FUNCTIONS
#########################################
title()
{
    clear
    echo "#################################################"
    echo "#    Mysql Server Installation Helper Script    #"
    echo "#################################################"
}
check_root()
{
    if [[ $EUID -ne 0 ]]; then
        title
        echo "Must be root to run this script!"
        sleep 2
        exit 1
    fi
}
check_os()
{
    if [[ $OSTYPE -ne linux-gnu ]]; then
        title
        echo "Script not compatible with your OS.."
        sleep 2
        exit 1
    fi
}
check_db()
{
    command -v mysql &>/dev/null
        if [[ $? == 1 ]]; then
            title
            echo "Mysql Database could not be found on your system."
            sleep 2
            echo "Installing now.."
            sleep 1
            apt install mysql-server mysql-client -y &>/dev/null
            echo "Installation complete.. Starting and Enabling Mysql now.."
            sleep 2
            systemctl start mysql &>/dev/null && systemctl enable mysql &>/dev/null
        fi
}
secure_installation()
{
    mysql <<BASH_QUERY
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PW');
FLUSH PRIVILEGES;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_USER_PW';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
BASH_QUERY
}
help_menu()
{
   title
   echo "Script installs the Mysql Database Server, as well as Phpmyadmin."
   echo "It also secures the Database server by running the mysql_secure_installation script."
   echo "Also adds an extra layer of security for the Phpmyadmin Web Interface by adding an additional login prompt."
   echo
   echo "Syntax: ./db-install.sh [-h]"
   echo "Usage:"
   echo "Must edit the script before running and fill in the variables at the top of the script."
   echo ""
   echo "Variables:"
   echo "MYSQL_USER= Insert a desired username for the newly created database user."
   echo "MYSQL_USER_PW= This will be the new database user's password."
   echo "MYSQL_ROOT_PW= This will be the database root user's password."
   echo ""
   echo "After the variables are filled in, make the script executable:"
   echo "chmod +x db-install.sh"
   echo "Then run it.."
   echo "./db-install.sh"
   echo ""
}

# SCRIPT
#########################################

# Ensure the script is ran with root privileges
check_root

# Check to make sure OS is compatable with script
check_os

# Help Menu
while getopts ":h" option; do
   case $option in
      h) 
         help_menu
         exit
         ;;
   esac
done

# Update and upgrade the system
apt update &>/dev/null && apt upgrade -y &>/dev/null

# Check to see if Mysql is installed already, if not install it
check_db

# Secure the Mysql Server
secure_installation

# Install phpmyadmin and required components
apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y &>/dev/null

# Enable mbstring php mod
phpenmod mbstring &>/dev/null

# Reload Apache2
systemctl reload apache2 &>/dev/null

# Enable htaccess file
sed -i "8i AllowOverride All" /etc/apache2/conf-available/phpmyadmin.conf &>/dev/null

# Create htaccess file
cat << _EOF_ >> /usr/share/phpmyadmin/.htaccess
AuthType Basic
AuthName "Restricted Files"
AuthUserFile /etc/phpmyadmin/.htpasswd
Require valid-user
_EOF_

# Generate new user for added layer of security for phpmyadmin
htpasswd -c /etc/phpmyadmin/.htpasswd $MYSQL_USER

# Reload Apache2
systemctl reload apache2 &>/dev/null

echo "Script Complete.."
sleep 3
