FROM php:7-apache

# Add the Sherwin Root Cert
USER root
ADD http://swroot.sherwin.com/swroot.pem /usr/local/share/ca-certificates/swroot.crt

# Install mysqli extensions
RUN docker-php-ext-install mysqli && \
    docker-php-ext-enable mysqli && \
    docker-php-ext-install pdo pdo_mysql && \
    docker-php-ext-enable pdo pdo_mysql

# Update the certificates, install mysql-client libaio1 wget vim cron
RUN update-ca-certificates && \
    apt-get update && \
    apt-get install -y default-mysql-client && \
    apt-get install -y --no-install-recommends libaio1 wget vim cron && \
    mkdir /var/www/html/inc

# Set Environment variable for mySQL connection
ENV MYSQL_SERVER_HOST=@MSQLSERVER@
ENV MYSQL_SERVER_PORT=3306
ENV MYSQL_USER=@DBUSER@
#ENV MYSQL_PASSWORD=@DBPASSWORD@ moved to k8s post deploy secret
ENV MYSQL_DATABASE=@DATABASENAME@
ENV MYSQL_CERT_PATH=/etc/mysql_cert/

# Install phpMyAdmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz && \
    tar -xvzf phpMyAdmin-5.2.1-all-languages.tar.gz && \
    rm -f phpMyAdmin-5.2.1-all-languages.tar.gz && \
    mv phpMyAdmin-5.2.1-all-languages /usr/share/phpmyadmin && \
    mkdir /usr/share/phpmyadmin/tmp && \
    chmod 777 /usr/share/phpmyadmin/tmp && \
    cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php && \
    chown -R www-data:www-data /usr/share/phpmyadmin && \
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Create phpMyAdmin config file
USER root
RUN echo "<?php" >/usr/share/phpmyadmin/config.inc.php && \
    echo "\$cfg['Servers'][1]['host'] = getenv('MYSQL_SERVER_HOST');"  >> /usr/share/phpmyadmin/config.inc.php && \
    echo "\$cfg['Servers'][1]['only_db'] = getenv('MYSQL_DATABASE');"  >> /usr/share/phpmyadmin/config.inc.php && \
>> /usr/share/phpmyadmin/config.ini.php

# Set Ownership of the config file
RUN chown -R www-data:www-data /usr/share/phpmyadmin/config.inc.php

# Copy PHP application code
#COPY ./php_content /var/www/html/

# Copy mySQL Cert
#COPY ./cert/DigiCertGlobalRootCA.crt.pem /etc/mysql_cert/

# Create a PHP info page for testing purposes
RUN echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php

# # Add the Cron Job Script
# COPY ./cron/cronjob.sh /usr/local/bin/cronjob.sh

# # Make Cronjob.sh executable
# RUN chmod +x /usr/local/bin/cronjob.sh

# # Add the cron job to crontab
# RUN echo "56 * * * * /usr/local/bin/cronjob.sh" >> /etc/crontab

# # Start Cron Service
# CMD ["sh", "-c", "cron && apache2-foreground"]


COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
