<!DOCTYPE html>
<head>
  <!-- STYLING -->
  <link rel="stylesheet" href="iamryancook.com/css/stylesheet.css">
</head>
<body>
  <u><h2>Server Setup</h2></u>
    <br>
     <h4>Table of Contents</h4>
  <ul>
    <li>Scripts</li>
    <li>Usage</li>
    <li>Customizing</li>
  </ul>
  <br>
  <u><h2>Scripts</h2></u>
  <u><h2>Apache Web Server setup script</h2></u>
  <strong>Usage</strong>
  <strong><p>./apache.sh -d DOMAIN.COM</p></strong><br>
  <p>Use -d when invoking the script to set the Domain name for your server.</p><br>
  <strong><p>./apache -i IP_ADDRESS</strong></p><br>
  <p>Using -i you can set your server's IP Address. The script uses this when creating the virtual host files.</p><br>
 <strong><p>./apache -e ADMIN@EXAMPLE.COM</strong></p><br>
  <p>Sets the admin email address. Used in virtual host files and generating the Lets Encrypt SSL</p><br>
  <strong><p>./apache -p 8.0</strong></p><br>
  <p>Tells the script what version of PHP you want installed.</p><br>
  <strong><p>./apache -s</strong></p><br>
  <p>Use -s if you want a Lets Encrypt SSL for your domain</p><br>
./apache.sh -h<br>
    This will display the help menu.</p>
  <u><h2>PHP Setup Script</h2></u>
  <strong>Usage</strong>
  <p>./php-setup.sh</p>
    <ul>
      <li>Increases PHP memory limit</li> 
      <li>Increases max upload file size</li> 
      <li>Sets the timezone</li> 
      <li>Sets the sendmail directory for the PHP mail function</li> 
      <li>Sets the mysql default socket, default user and password for database connections.</li>
  </ul>
  <br>
  <p><strong>Sendonly-mail.sh</strong>- Configures the server to be a sendonly smtp server for use with forms. Script generates a dkim key and prints it on a txt file named DNS_RECORD.txt. You must add this dkim to your dns records in order for it to work.</p>
  
