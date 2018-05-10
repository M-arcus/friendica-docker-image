#!/usr/bin/env node

'use strict';

require('chromedriver');

var execSync = require('child_process').execSync,
    expect = require('expect.js'),
    fs = require('fs'),
    net = require('net'),
    path = require('path'),
    superagent = require('superagent'),
    util = require('util'),
    webdriver = require('selenium-webdriver');

var by = webdriver.By,
    until = webdriver.until,
    Builder = require('selenium-webdriver').Builder;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

if (!process.env.USERNAME || !process.env.PASSWORD) {
    console.log('USERNAME and PASSWORD env vars need to be set');
    process.exit(1);
}

describe('Application life cycle test', function () {
    this.timeout(0);

    var server, browser = new Builder().forBrowser('chrome').build();

    before(function (done) {
        var seleniumJar= require('selenium-server-standalone-jar');
        var SeleniumServer = require('selenium-webdriver/remote').SeleniumServer;
        server = new SeleniumServer(seleniumJar.path, { port: 4444 });
        server.start();

        done();
    });

    after(function (done) {
        browser.quit();
        server.stop();
        done();
    });

    var LOCATION = 'test';
    var TEST_TIMEOUT = 50000;
    var app;

    function waitForElement(elem, callback) {
         browser.wait(until.elementLocated(elem), TEST_TIMEOUT).then(function () {
            browser.wait(until.elementIsVisible(browser.findElement(elem)), TEST_TIMEOUT).then(function () {
                callback();
            });
        });
    }

    function welcomePage(callback) {
        browser.get('https://' + app.fqdn);

        waitForElement(by.xpath('//*[text()="Cloudron LAMP App"]'), function () {
            waitForElement(by.xpath('//*[text()="PHP Version 7.0.28-0ubuntu0.16.04.1"]'), callback);
        });
    }

    function uploadedFileExists(callback) {
        browser.get('https://' + app.fqdn + '/test.php');

        waitForElement(by.xpath('//*[text()="this works"]'), function () {
            waitForElement(by.xpath('//*[text()="' + app.fqdn + '"]'), callback);
        });
    }

    function checkPhpMyAdmin(callback) {
        superagent.get('https://' + app.fqdn + '/phpmyadmin').end(function (error, result) {
            if (error && !error.response) return callback(error); // network error

            if (result.statusCode !== 401) return callback('Expecting 401 error');

            superagent.get('https://' + app.fqdn + '/phpmyadmin')
                .auth(process.env.USERNAME, process.env.PASSWORD)
                .end(function (error, result) {
                if (error) return callback(error);

                if (result.text.indexOf(`${app.fqdn} / mysql | phpMyAdmin`) === -1) { // in the <title>
                    console.log(result.text);
                    return callback(new Error('could not detect phpmyadmin'));
                }

                callback();
            });
        });
    }

    function checkCron(callback) {
        this.timeout(60000 * 2);

        fs.writeFileSync('/tmp/crontab', '* * * * * echo -n "$MYSQL_HOST" > /app/data/public/cron\n', 'utf8');
        execSync('cloudron push /tmp/crontab /app/data/crontab');
        fs.unlinkSync('/tmp/crontab');

        execSync('cloudron restart --wait');

        console.log('Waiting for crontab to trigger');

        setTimeout(function () {
            superagent.get('https://' + app.fqdn + '/cron').end(function (error, result) {
                if (error && !error.response) return callback(error); // network error

                if (result.statusCode !== 200) return callback('Expecting 200, got ' + result.statusCode);

                if (result.text !== 'mysql') return callback('Unexpected text: ' + result.text);

                callback();
            });
        }, 60 * 1000); // give it a minute to run the crontab
    }

    xit('build app', function () {
        execSync('cloudron build', { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('install app', function () {
        execSync('cloudron install --new --wait --location ' + LOCATION, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('can get app information', function () {
        var inspect = JSON.parse(execSync('cloudron inspect'));

        app = inspect.apps.filter(function (a) { return a.location === LOCATION; })[0];

        expect(app).to.be.an('object');
    });

    it('can view welcome page', welcomePage);
    it('can upload file with sftp', function () {
        // remove from known hosts in case this test was run on other apps with the same domain already
        // if the tests fail here you want to set "HashKnownHosts no" in ~/.ssh/config
        execSync(util.format('sed -i \'/%s/d\' -i ~/.ssh/known_hosts', app.fqdn));
        execSync(util.format('lftp sftp://%s:%s@%s:%s  -e "set sftp:auto-confirm yes; cd public/; put test.php; bye"', process.env.USERNAME, process.env.PASSWORD, app.fqdn, app.portBindings.SFTP_PORT));
    });
    it('can get uploaded file', uploadedFileExists);
    it('can access phpmyadmin', checkPhpMyAdmin);
    it('executes cron tasks', checkCron);

    it('backup app', function () {
        execSync('cloudron backup create --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('restore app', function () {
        execSync('cloudron restore --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    it('can get uploaded file', uploadedFileExists);

    it('move to different location', function () {
        browser.manage().deleteAllCookies();
        execSync('cloudron configure --wait --location ' + LOCATION + '2 --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
        var inspect = JSON.parse(execSync('cloudron inspect'));
        app = inspect.apps.filter(function (a) { return a.location === LOCATION + '2'; })[0];
        expect(app).to.be.an('object');
    });

    it('can get uploaded file', uploadedFileExists);
    it('can access phpmyadmin', checkPhpMyAdmin);

    // disable SFTP
    it('can disable sftp', function () {
        execSync('cloudron configure --wait -p SFTP_PORT=', { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });
    it('(nosftp) can view welcome page', welcomePage);
    it('(nosftp cannot upload file with sftp', function (done) {
        var client = new net.Socket();
        client.setTimeout(10000);

        client.connect(2222, app.fqdn, function() {
            client.destroy();
            done(new Error('Connected'));
        });

        client.on('timeout', function () { client.destroy(); done(); }); // the packet just got dropped (good)

        client.on('error', function (error) {
            client.destroy();
            done(new Error('Should have got timeout but got error:' + error.message));
        });
    });

    it('(nosftp) cannot access phpmyadmin', function (done) {
        superagent.get('https://' + app.fqdn + '/phpmyadmin').end(function (error, result) {
            if (error && !error.response) return done(error); // network error

            if (result.statusCode !== 404) return done('Expecting 404 error');

            done();
        });
    });

    it('uninstall app', function () {
        execSync('cloudron uninstall --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });

    // test update
    it('can install app', function () {
        execSync('cloudron install --new --wait --appstore-id lamp.cloudronapp --location ' + LOCATION, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
        var inspect = JSON.parse(execSync('cloudron inspect'));
        app = inspect.apps.filter(function (a) { return a.location === LOCATION; })[0];
        expect(app).to.be.an('object');
    });
    it('can upload file with sftp', function () {
        // remove from known hosts in case this test was run on other apps with the same domain already
        // if the tests fail here you want to set "HashKnownHosts no" in ~/.ssh/config
        execSync(util.format('sed -i \'/%s/d\' -i ~/.ssh/known_hosts', app.fqdn));
        execSync(util.format('lftp sftp://%s:%s@%s:%s  -e "set sftp:auto-confirm yes; cd public/; put test.php; bye"', process.env.USERNAME, process.env.PASSWORD, app.fqdn, app.portBindings.SFTP_PORT));
    });

    it('can update', function () {
        execSync('cloudron install --wait --app ' + LOCATION, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });
    it('can get uploaded file', uploadedFileExists);
    it('can access phpmyadmin', checkPhpMyAdmin);

    it('uninstall app', function () {
        execSync('cloudron uninstall --app ' + app.id, { cwd: path.resolve(__dirname, '..'), stdio: 'inherit' });
    });
});
