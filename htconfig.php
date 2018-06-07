<?php

// If automatic system installation fails:


//die('The configuration you did manually contains some mistakes. Please have a look at your .htconfig.php file.');
// If you are doing the configuration manually, please remove the line above


// Copy or rename this file to .htconfig.php

// Why .htconfig.php? Because it contains sensitive information which could
// give somebody complete control of your database. Apache's default
// configuration denies access to and refuses to serve any file beginning
// with .ht

// Then set the following for your MySQL installation

$db_host = 'your.mysqlhost.com';
$db_user = 'mysqlusername';
$db_pass = 'mysqlpassword';
$db_data = 'mysqldatabasename';

// Use environment variables for mysql if they are set beforehand
if (!empty(getenv('MYSQL_HOST'))
    && !empty(getenv('MYSQL_PORT'))
    && !empty(getenv('MYSQL_USERNAME'))
    && !empty(getenv('MYSQL_PASSWORD'))
    && !empty(getenv('MYSQL_DATABASE'))) {
    $db_host = getenv('MYSQL_HOST') . ':' . getenv('MYSQL_PORT');
    $db_user = getenv('MYSQL_USERNAME');
    $db_pass = getenv('MYSQL_PASSWORD');
    $db_data = getenv('MYSQL_DATABASE');
}

// Set the database connection charset to full Unicode (utf8mb4).
// Changing this value will likely corrupt the special characters.
// You have been warned.
$a->config['system']['db_charset'] = 'utf8mb4';

// Choose a legal default timezone. If you are unsure, use "America/Los_Angeles".
// It can be changed later and only applies to timestamps for anonymous viewers.

$default_timezone = 'Europe/Berlin';

// Default system language

$a->config['system']['language'] = 'de';

// What is your site name?

$a->config['sitename'] = "Friendica Social Network";

// Your choices are REGISTER_OPEN, REGISTER_APPROVE, or REGISTER_CLOSED.
// Be certain to create your own personal account before setting
// REGISTER_CLOSED. 'register_text' (if set) will be displayed prominently on
// the registration page. REGISTER_APPROVE requires you set 'admin_email'
// to the email address of an already registered person who can authorise
// and/or approve/deny the request.

// In order to perform system administration via the admin panel, admin_email
// must precisely match the email address of the person logged in.

$a->config['register_policy'] = REGISTER_APPROVE;
$a->config['register_text'] = '';
$a->config['admin_email'] = 'admin@example.com';

// Maximum size of an imported message, 0 is unlimited

$a->config['max_import_size'] = 200000;

// maximum size of uploaded photos

$a->config['system']['maximagesize'] = 800000;

// Location of PHP command line processor

$a->config['php_path'] = 'php';

// Server-to-server private message encryption (RINO) is allowed by default.
// set to 0 to disable, 1 to enable

$a->config['system']['rino_encrypt'] = 1;

// allowed themes (change this from admin panel after installation)

$a->config['system']['allowed_themes'] = 'frio';

// default system theme

$a->config['system']['theme'] = 'frio';


// By default allow pseudonyms

$a->config['system']['no_regfullname'] = true;

//Deny public access to the local directory
//$a->config['system']['block_local_dir'] = false;

// Location of the global directory
$a->config['system']['directory'] = getenv('APP_ORIGIN');

// Allowed protocols in link URLs; HTTP protocols always are accepted
$a->config['system']['allowed_link_protocols'] = ['ftp', 'ftps', 'mailto', 'cid', 'gopher'];

// Authentication cookie lifetime, in days
$a->config['system']['auth_cookie_lifetime'] = 7;

$a->config['system']['smtp'] = true;
$a->config['system']['smtp_server'] = getenv('MAIL_SMTP_SERVER');
$a->config['system']['smtp_port'] = getenv('MAIL_SMTP_PORT');
$a->condig['system']['smtp_port_s'] = getenv('MAIL_SMTPS_PORT');
$a->config['system']['smtp_username'] = getenv('MAIL_SMTP_USERNAME');
$a->config['system']['smtp_password'] = getenv('MAIL_SMTP_PASSWORD');
$a->config['system']['smtp_from'] = getenv('MAIL_FROM');
$a->config['system']['smtp_domain'] = getenv('MAIL_DOMAIN');
$a->config['system']['smtp_secure'] = 'tls';
