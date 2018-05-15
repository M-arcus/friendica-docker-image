#!/bin/bash

set -eu

mkdir -p /app/data/public /run/apache2 /run/proftpd /run/app /run/cron

if ! [ -f /app/data/.initialized ]; then
  echo "Fresh installation, setting up data directory..."

  # Setup commands here
  echo "Copying crontab file"
  cp /app/code/crontab /app/data/
  echo "Copying crontab file finished"

  echo "Copying Friendica code"
  cp -rf /app/code/friendica/* /app/data/public/
  echo "Copying finished"

  echo "Starting automatic installation"
  cd /app/data/public/
  bin/console autoinstall
  cd /app/data
  echo "Installation done"

  touch /app/data/.initialized
  echo "Done."
fi

# cleanup for old apache2-app.conf
rm -f /app/data/apache2-app.conf

if [ ! -f "/app/data/php.ini" ]; then
    cp /etc/php/7.0/apache2/php.ini.orig /app/data/php.ini
else
    crudini --set /app/data/php.ini Session session.gc_probability 1
    crudini --set /app/data/php.ini Session session.gc_divisor 100
fi

# SFTP_PORT can be unset to disable SFTP
disable_sftp="false"
if [[ -z "${SFTP_PORT:-}" ]]; then
    echo "SSH disabled"
    SFTP_PORT=29418 # arbitrary port to keep sshd happy
    disable_sftp="true"
else
    sed -e "s,##SERVER_NAME,${APP_DOMAIN}," \
        -e "s/##SFTP_PORT/${SFTP_PORT}/" \
        -e "s,##LDAP_URL,${LDAP_URL},g" \
        -e "s/##LDAP_BIND_DN/${LDAP_BIND_DN}/g" \
        -e "s/##LDAP_BIND_PASSWORD/${LDAP_BIND_PASSWORD}/g" \
        -e "s/##LDAP_USERS_BASE_DN/${LDAP_USERS_BASE_DN}/g" \
        -e "s/##LDAP_UID/$(id -u www-data)/g" \
        -e "s/##LDAP_GID/$(id -g www-data)/g" \
        /app/code/proftpd.conf.template > /run/proftpd/proftpd.conf

    if [[ -f /app/data/public/index.php ]]; then
        sed -e "s,^sftp -P.*public/$,sftp -P ${SFTP_PORT} ${APP_DOMAIN}:public/," \
            -i /app/data/public/index.php
    fi
fi

if [[ ! -f "/app/data/sftpd/ssh_host_ed25519_key" ]]; then
    echo "Generating ssh host keys"
    mkdir -p /app/data/sftpd
    ssh-keygen -qt rsa -N '' -f /app/data/sftpd/ssh_host_rsa_key
    ssh-keygen -qt dsa -N '' -f /app/data/sftpd/ssh_host_dsa_key
    ssh-keygen -qt ecdsa -N '' -f /app/data/sftpd/ssh_host_ecdsa_key
    ssh-keygen -qt ed25519 -N '' -f /app/data/sftpd/ssh_host_ed25519_key
else
    echo "Reusing existing host keys"
fi

chmod 0600 /app/data/sftpd/*_key
chmod 0644 /app/data/sftpd/*.pub

## Generate apache config. PMA is disabled based on SFTP config
if [[ "${disable_sftp}" == "true" ]]; then
    echo "PMA disabled"
    sed '/.*PMA BEGIN/,/.*PMA END/d' /app/code/apache2-app.conf > /run/apache2/app.conf
else
    sed -e "s@AuthLDAPURL .*@AuthLDAPURL ${LDAP_URL}/${LDAP_USERS_BASE_DN}?username??(objectclass=user)@" \
        -e "s@AuthLDAPBindDN .*@AuthLDAPBindDN ${LDAP_BIND_DN}@" \
        -e "s@AuthLDAPBindPassword .*@AuthLDAPBindPassword ${LDAP_BIND_PASSWORD}@" \
        /app/code/apache2-app.conf > /run/apache2/app.conf
fi

## hook for custom start script in /app/data/run.sh
if [ -f "/app/data/run.sh" ]; then
    /bin/bash /app/data/run.sh
fi

## configure in-container Crontab
if [ -f "/app/data/crontab" ]; then
    # http://www.gsp.com/cgi-bin/man.cgi?section=5&topic=crontab
    if ! (env; cat /app/data/crontab; echo -e '\nMAILTO=""') | crontab -u www-data -; then
        echo "Error importing crontab. Continuing anyway"
    else
        echo "Imported crontab"
    fi
fi

chown -R www-data:www-data /app/data /run/apache2 /run/proftpd /run/app

echo "Starting supervisord"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i Lamp
