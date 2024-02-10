#!/bin/bash

# Replace placeholders in configuration files with actual database connection details
sed -i "s/localhost/'${MYSQL_SERVER_HOST}'/g" /usr/share/phpmyadmin/config.sample.inc.php
sed -i "s/AllowNoPassword' => false/AllowNoPassword' => true/g" /usr/share/phpmyadmin/config.sample.inc.php
sed -i "s/cookie/cookie\n\$cfg['Servers'][\$i]['host'] = '${MYSQL_SERVER_HOST}';\n\$cfg['Servers'][\$i]['user'] = '${MYSQL_USER}';\n\$cfg['Servers'][\$i]['password'] = '${MYSQL_PASSWORD}';/g" /usr/share/phpmyadmin/config.sample.inc.php 

# Start the Apache web serv
