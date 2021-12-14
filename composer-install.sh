#!/usr/bin/env bash
########################################################################
# Author: Ryan C. https://github.com/ryanc410
# Date: 08-24-2021
# Version: 2.0
# Description: Installs Composer PHP package manager 
########################################################################
# VARIABLES
########################################################################
ret_val="$?"
HASH=$(curl -sS https://composer.github.io/installer.sig)
########################################################################
# FUNCTIONS
########################################################################
function check_os()
{
    cat /etc/lsb-release | grep 20 &>/dev/null
    if [[ $ret_val != 0 ]]; then
        sudo apt install software-properties-common -y
        sudo add-apt-repository ppa:ondrej/php -y
        sudo apt update
        sudo apt install php7.4 -y
    else
        sudo apt install php7.4 -y
    fi
}
########################################################################
# SCRIPT
########################################################################
sudo apt update && sudo apt upgrade -y
php -v &>/dev/null

if [[ $retval != 0 ]]; then
    echo "ERROR: Composer needs PHP to function.. Do you want to install PHP now?"
    read opt
    case "$opt" in
        y|Y|yes|Yes|YES)
            check_os
            ;;
        n|N|no|No|NO)
            echo "Exiting script.."
            sleep 2
            exit 0
            ;;
        *)
            echo "Invalid Response.."
            exit 1
            ;;
    esac
fi

dpkg -l | grep php-cli &>/dev/null
if [[ $ret_val != 0 ]]; then
    sudo apt install php-cli -y
fi

dpkg -l | grep unzip &>/dev/null
if [[ $ret_val != 0 ]]; then
    sudo apt install unzip -y
fi

cd ~
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
[ -f /usr/local/bin/composer ] && echo "Composer Successfully Installed!" || echo "Installation failed!"
