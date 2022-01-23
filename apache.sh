#!/usr/bin/env bash
###############################################################
# SCRIPT: https://github.com/ryanc410/server-setup/apache.sh  #
# AUTHOR: Ryan Cook                                           #
# DATE: 10/18/2021                                            #
# LAST UPDATED: 01/23/2022                                    #
# VERSION: 3.0                                                #
# DESCRIPTION: Configure the Apache Web Server                #
###############################################################
#     VARIABLES     #
#####################
exit_stat=$?

#####################
#     FUNCTIONS     #
#####################
function title()
{
    clear
    echo "#*************************************#"
    echo "#     APACHE CONFIGURATION SCRIPT     #"
    echo "#*************************************#"
    echo ""
}
function usage()
}
    clear
    echo "Script installs Apache and configures a new virtual host."
    echo
    echo "Syntax: apache.sh [OPTIONS]"
    echo "OPTIONS:"
    echo "-v|--version          Print software version and exit."
    echo "-h|--help             Show this usage screen."
    echo
}

##################
#     SCRIPT     #
##################
while [[ $# > 0 ]]
    do
        case "$1" in
            -h | --help)    usage
                            shift
                            exit 0
                            ;;
            -v | --version) clear
                            shift
                            echo "Apache Configuration Script V3.0"
                            sleep 5
                            exit 0
                            ;;
        esac
    done
title
echo "This script will automatically install and configure the Apache Web Server."
sleep 2
title
echo "What Domain do you want to associate with this server?"
read domain_name
host "$domain_name" &>/dev/null
while [[ $exit_stat != 0 ]]; do
    title
    echo "The Domain you entered, $domain_name, could not be found. Please check the spelling."
    sleep 3
    title
    echo "What Domain do you want to associate with this server?"
    read domain_name
done

title
echo "The script will now install and configure Apache."
sleep 2
echo "Press [ENTER] to begin."
read
# Update server packages and repositories
apt update && apt upgrade -y
# Install Apache
apt install apache2 apache2-utils -y &>/dev/null
# Check to make sure apache was installed
dpkg -l | grep apache2 &>/dev/null
if [[ $exit_stat == 0 ]]; then
    echo "The Apache web server has been installed successfully."
    sleep 2
else
    echo "There was a problem installing Apache."
    sleep 2
    exit 2
fi
# Enable apache to run on system boot and start apache
systemctl enable apache2
systemctl start apache2 
# Generate servername.conf to suppress fqdn error
echo "ServerName localhost">>/etc/apache2/conf-available/servername.conf
# Enable servername.conf
a2enconf servername.conf
# Create Web Root directory
mkdir /var/www/"$domain_name"
# Remove directory indexing
sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf
# Reload apache2
systemctl reload apache2
# Disable default virtual host
a2dissite 000-default.conf
# Create new Virtual Host
cat >> /etc/apache2/sites-available/"$domain_name".conf <<-_EOF_
<VirtualHost *:80>
    ServerName $domain_name
    ServerAlias www.$domain_name
    ServerAdmin admin@$domain_name

    DocumentRoot /var/www/$domain_name

    ErrorLog \${APACHE_LOG_DIR}/$domain_name-error.log
    CustomLog '${APACHE_LOG_DIR}'/$domain_name-access.log combined
</VirtualHost>
_EOF_
# Enable new Virtual Host
a2ensite "$domain_name".conf
# Reload apache2
systemctl reload apache2
# Check for syntax errors
apache2ctl -t
if [[ $exit_stat == 0 ]]; then
    title
    echo "The script was successful installing and configuring the Apache webserver for the Domain, $domain_name."
    sleep 3
    exit 0
else
    title
    echo "Something went wrong with the configuration of Apache."
    sleep 3
    exit 1
fi
