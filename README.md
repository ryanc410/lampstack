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
  <p><strong>PHP-Setup.sh</strong>- Sets these values  in all of the php.ini files with one command: 
    <ul>
      <li>Increases PHP memory limit</li> 
      <li>Increases max upload file size</li> 
      <li>Sets the timezone</li> 
      <li>Sets the sendmail directory for the PHP mail function</li> 
      <li>Sets the mysql default socket, default user and password for database connections.</li>
  </ul>
  <br>
  <p><strong>Sendonly-mail.sh</strong>- Configures the server to be a sendonly smtp server for use with forms. Script generates a dkim key and prints it on a txt file named DNS_RECORD.txt. You must add this dkim to your dns records in order for it to work.</p>
  
