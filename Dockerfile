FROM cloudron/base:0.10.0
MAINTAINER Johannes Zellner <johannes@cloudron.io>

RUN mkdir -p /app/code /run/app/sessions
WORKDIR /app/code

RUN apt-get update && apt-get install -y php libapache2-mod-php crudini \
    php-redis \
    php-bcmath \
    php-bz2 \
    php-curl \
    php-date \
    php-dba \
    php-enchant \
    php-gd \
    php-geoip \
    php-gettext \
    php-imap \
    php-json \
    php-log \
    php-mbstring \
    php-mcrypt \
    php-mime-type \
    php-mysql \
    php-pdfparser \
    php-readline \
    php-soap \
    php-sql-formatter \
    php-sqlite3 \
    php-tcpdf \
    php-timer \
    php-twig \
    php-uuid \
    php-validate \
    php-xml \
    php-xml-parser \
    php-xml-svg \
    php-yac \
    php-zip \
    php-imagick \
    proftpd proftpd-mod-ldap \
    cron \
    git \
    && rm -rf /var/cache/apt /var/lib/apt/lists /etc/ssh_host_*

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
RUN sed -e "s,MaxSpareServers[^:].*,MaxSpareServers 5," -i /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
RUN echo "Listen 80" > /etc/apache2/ports.conf
RUN a2enmod rewrite authnz_ldap headers

# configure mod_php
RUN crudini --set /etc/php/7.0/apache2/php.ini PHP upload_max_filesize 64M && \
    crudini --set /etc/php/7.0/apache2/php.ini PHP post_max_size 64M && \
    crudini --set /etc/php/7.0/apache2/php.ini PHP memory_limit 128M && \
    crudini --set /etc/php/7.0/apache2/php.ini Session session.save_path /run/app/sessions && \
    crudini --set /etc/php/7.0/apache2/php.ini Session session.gc_probability 1 && \
    crudini --set /etc/php/7.0/apache2/php.ini Session session.gc_divisor 100

RUN mv /etc/php/7.0/apache2/php.ini /etc/php/7.0/apache2/php.ini.orig && ln -sf /app/data/php.ini /etc/php/7.0/apache2/php.ini

# configure site
COPY apache2-app.conf /app/code/apache2-app.conf
RUN ln -s /run/apache2/app.conf /etc/apache2/sites-enabled/app.conf

# phpMyAdmin
RUN mkdir -p /app/code/phpmyadmin && \
    curl -L https://files.phpmyadmin.net/phpMyAdmin/4.7.0/phpMyAdmin-4.7.0-english.tar.gz | tar zxvf - -C /app/code/phpmyadmin --strip-components=1
COPY phpmyadmin-config.inc.php /app/code/phpmyadmin/config.inc.php

# configure proftpd
ADD proftpd.conf /app/code/proftpd.conf.template

RUN rm -rf /var/log/proftpd && ln -s /run/proftpd /var/log/proftpd

# configure cron
RUN rm -rf /var/spool/cron && ln -s /run/cron /var/spool/cron
# clear out the crontab
RUN rm -f /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/* && truncate -s0 /etc/crontab

# configure supervisor
ADD supervisor/ /etc/supervisor/conf.d/
RUN sed -e 's,^logfile=.*$,logfile=/run/supervisord.log,' -i /etc/supervisor/supervisord.conf

# add code
COPY start.sh crontab /app/code/

# forgotten in the base image
RUN chmod +x /usr/local/bin/composer

# copy code from github
RUN git clone https://github.com/friendica/friendica.git /app/code/friendica

# navigate to friendica dir
WORKDIR /app/code/friendica

# checkout specific version
RUN git checkout 0848cef605bb6773852809a9cf3af5a5cc26bb10

#install composer packages
RUN /usr/local/bin/composer install --optimize-autoloader

# install addons
RUN git clone https://github.com/m-arcus/friendica-addons.git addon

# copy config file
COPY htconfig.php /app/code/friendica/

# make cloudron exec sane
WORKDIR /app/data

CMD [ "/app/code/start.sh" ]
