# Server Setup Script Library

This github repository contains a set of scripts to configure a linux server with the basic foundation needed for Web Development.

# Installation

```bash
git clone https://github.com/ryanc410/server-setup

# OUTPUT

Cloning into 'server-setup'...
remote: Enumerating objects: 108, done.
remote: Counting objects: 100% (108/108), done.
remote: Compressing objects: 100% (107/107), done.
remote: Total 108 (delta 54), reused 0 (delta 0), pack-reused 0
Receiving objects: 100% (108/108), 53.06 KiB | 2.21 MiB/s, done.
Resolving deltas: 100% (54/54), done.

cd server-setup
chmod +x apache.sh php-setup.sh db-install.sh sendonly-mail.sh
```

# apache.sh

Configures the Apache Web Server. Creates a new Virtual Host and does a basic initial configuration of apache when it is freshly installed.

The script can take arguments to help customize the installation process to better suit your environment.

OPTIONS

#### -d|--domain   [example.com] &nbsp; &nbsp; &nbsp; &nbsp;         Specify the domain you want the script to configure apache for.
#### -i|--ip       [192.168.1.1] &nbsp; &nbsp; &nbsp; &nbsp;         Specify the IP Address associated with provided domain.
#### -w|--webroot  [/path/to/webroot] &nbsp;&nbsp;&nbsp; Set the Web Root Directory.
#### -v|--version &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Print Script version # and exit.
#### -h|--help &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Prints the usage menu.


