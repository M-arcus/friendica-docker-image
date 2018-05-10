<?php
$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'config';

/* Server parameters */
$cfg['Servers'][$i]['host'] = getenv("MYSQL_HOST");
$cfg['Servers'][$i]['port'] = getenv("MYSQL_PORT");
$cfg['Servers'][$i]['user'] = getenv("MYSQL_USERNAME");
$cfg['Servers'][$i]['password'] = getenv("MYSQL_PASSWORD");
$cfg['Servers'][$i]['only_db'] = array(getenv("MYSQL_DATABASE"));

$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;

$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';

