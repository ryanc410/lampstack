#!/bin/bash
#
# Author: Ryan Cook
# Date: 08/24/2021
# Description: Installs Composer quickly

check_root()
{
    if [[ $EUID -ne 0 ]]; then
        clear
        echo "Must be root to run this script!"
        sleep 2
        exit 1
    fi
}
check_os()
{
    if [[ $OSTYPE -ne linux-gnu ]]; then
        clear
        echo "Script not compatible with your OS.."
        sleep 2
        exit 1
    fi
}
title()
{
    clear
    echo "############################"
    echo "#    Composer Installer    #"
    echo "############################"
}

check_os

check_root


echo "Updating system.."
apt update &>/dev/null

echo "Installing required components.."
apt install php-cli unzip -y &>/dev/null

command -v curl &>/dev/null
if [[ $? == 1 ]]; then
    apt install curl -y &>/dev/null
fi

echo "Downloading Composer Install Script.."
curl -sS https://getcomposer.org/installer -o composer-setup.php &>/dev/null

echo "Installing.."
php composer-setup.php --install-dir=/usr/local/bin --filename=composer &>/dev/null

echo "Installation Complete!"
