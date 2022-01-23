

# About Server-Setup

This repository contains a collection of scripts that automatically install and configure a LAMP stack. It is the result of learning through trial and error, and the amount of times I had to wipe my server and start from scratch motivated me to create this set of scripts. Maybe it will help delay my carpel tunnel, but probably not. Atleast I wont have to type all these commands in over and over again, and hopefully these scripts will be of some use to someone out there learning Web Development and needing a LAMP stack as a foundation..

# Scripts

### **apache.sh**
The main purpose of this script is to install the Apache2 Web Server, and configure a new virtual host using a Domain
name supplied by the person who executed the script. It prompts for you to enter the Domain that you wish to configure Apache with and then does it's thing. There are no arguments to pass, the script is extremely straight forward.

### **apache-ssl.sh**
In order to run this script, Apache2 should already be installed and have a virtual host configured. The script will verify the Domain to be secured with SSL before running. After verifying the Domain, the required Apache modules will be enabled (http2, ssl, headers). An alias is then setup to be used by Lets Encrypt in the Domain verification process. Then a configuration file containing SSL parameters is created followed by a Diffie Helman certificate being generated. The Diffie Helman may take some time, depending on your server's hardware. Next up the script runs the certbot command and requests the certificate. **If your DNS settings are not configured correctly this step will FAIL**. Example DNS Record configuration:
| TYPE | HOST | VALUE | TTL |
|------|------|-------|-----|
| A | @ | SERVER_IPADDRESS | Auto |
| A | www | SERVER_IPADDRESS | Auto |

