## Cloudron Friendica Stack

A personal social network
Keep in contact with people you care about.

### Setup

Use 'admin@example.com' for the email admin account.

### SFTP

This app also bundles [ProFTPD](http://www.proftpd.org/) which provides `sftp://` access. Use your preferred ftp client to manage all files on the server. The `public` folder contains your PHP files. You will find `php.ini` at the root directory.

### Cron

This app supports running one or more cronjobs. The jobs are specified using the standard crontab syntax.

### Remote Terminal

Use the [web terminal](https://cloudron.io/documentation/apps/#web-terminal) for a remote shell connection into the
app to adjust configuration files like `php.ini`.

PHP Version: <upstream>PHP 7</upstream>
