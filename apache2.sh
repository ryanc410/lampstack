#!/usr/bin/env bash

domain=
ip_address=
webroot=
modsecurity=false
modsec_dir=/etc/apache2/modsecurity-crs/

function enable()
{
    systemctl enable "$1"
    systemctl start "$1"
}
# If not executed by root, print error and exit
if [[ $EUID != 0 ]]; then
    echo "Must be root to run this script.."
    sleep 3
    exit 1
fi

while [ $# != 0 ];
do
    case "$1" in
        -d | --domain )     shift
                            domain=$1
                            ;;
        -h | --help )       usage
                            shift
                            ;;
        -i | --ip )         shift
                            ip_address=$1
                            ;;
        -m | --modsec )     modsecurity=true
                            shift
                            ;;
        -w | --webroot )    shift
                            webroot=$1
                            ;;
        *)                  echo "$1 is not a valid option."
                            sleep 3
                            usage
                            exit 1
                            ;;
    esac
done

# Update repositories and upgrade packages
apt update 
apt upgrade -y
# Install Apache2 web server
apt install apache2 apache2-utils -y
# Run the enable function with apache as an argument
enable apache2
# Create servername.conf to suppress fqdn error
echo "ServerName localhost">>/etc/apache2/conf-available/servername.conf
# Disable default virtualhost
a2dissite 000-default.conf
# Create new virtualhost for domain
cat >> /etc/apache2/sites-available/"$domain".conf<<-_EOF_
<VirtualHost $ip_address:80>
    ServerName $domain
    ServerAlias www.$domain
    ServerAdmin admin@$domain

    DocumentRoot $webroot

    ErrorLog '${APACHE_LOG_DIR}'/$domain-error.log
    CustomLog '${APACHE_LOG_DIR}'/$domain-access.log combined
</VirtualHost>
_EOF_
# Enable new virtualhost
a2ensite "$domain".conf
# Remove webroot indexing for security reasons
sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf
# Reload apache
systemctl reload apache2
# If mod security was chosen to be installed, install it
if [[ $modsecurity = true ]]; then
    # Install modsecurity module
    apt install libapache2-mod-security2 -y
    # Enable modsecurity module
    a2enmod security2
    # Restart apache
    systemctl restart apache2
    # Rename modsecurity recommended conf file
    mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf

    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/modsecurity/modsecurity.conf

    sed -i 's/SecAuditLogParts ABDEFHIJZ/SecAuditLogParts ABCEFHJKZ/g' /etc/modsecurity/modsecurity.conf

    systemctl restart apache2

    command -v wget &>/dev/null
    if [[ $? != 0 ]]; then
        apt install wget -y
    fi

    wget https://github.com/coreruleset/coreruleset/archive/v3.3.0.tar.gz

    tar xvf v3.3.0.tar.gz &>/dev/null

    mkdir "$modsec_dir"

    mv coreruleset-3.3.0/ /etc/apache2/modsecurity-crs/

    mv "$modsec_dir"coreruleset-3.3.0/crs-setup.conf.example "$modsec_dir"coreruleset-3.3.0/crs-setup.conf

    cat >> /etc/apache2/mods-enabled/security2.conf<<_EOF_
<IfModule security2_module>
    SecDataDir /var/cache/modsecurity

    IncludeOptional /etc/modsecurity/*.conf
    IncludeOptional /etc/apache2/modsecurity-crs/coreruleset-3.3.0/crs-setup.conf
    IncludeOptional /etc/apache2/modsecurity-crs/coreruleset-3.3.0/rules/*.conf
</IfModule>
_EOF_

    apache2ctl -t &>/dev/null
    if [[ $? != 0 ]]; then
        echo "There was a problem configuring Apaches Mod Security.."
        sleep 2
        exit 1
    else
        echo "Mod Security has been successfully configured!"
        sleep 3
        systemctl restart apache2
    fi
else
    apache2ctl -t &>/dev/null
    if [[ $? != 0 ]]; then
        echo "There was a problem configuring apache.."
        sleep 3
        exit 1
    else
        clear
        echo "Apache has been configured successfully!"
        echo 
        echo "DOMAIN:               $domain"
        echo "IP ADDRESS:           $ip_address"
        echo "WEBROOT DIRECTORY:    $webroot"
        echo "VHOST FILE:           /etc/apache2/sites-available/"$domain".conf"
        echo "LOGS:                '${APACHE_LOG_DIR}'/$domain-error.log"
        echo "                     '${APACHE_LOG_DIR}'/$domain-access.log combined"
        echo ""
        echo "WEB DIRECTORY INDEXING DISABLED"
        sleep 3
        exit 0
    fi
fi
