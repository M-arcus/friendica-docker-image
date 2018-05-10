# Friendica Cloudron App

This repository contains the Cloudron app package source for Friendica.

## Installation

1. Clone this repo
2. Execute `cloudron build` inside the main directory
3. Execute `cloudron install -l <the app-location>`

### Alternative (not yet possible)

[![Install](https://cloudron.io/img/button.svg)](https://cloudron.io/button.html?app=org.friendica.cloudronapp)

or using the [Cloudron command line tooling](https://cloudron.io/references/cli.html)

```
cloudron install --appstore-id friendica.cloudronapp
```

## Registration

Please set your starting email to 'admin@example.com' when first registering.
Only then you will recieve admin rights.
Be sure to change the email after registering.

## Building

The app package can be built using the [Cloudron command line tooling](https://cloudron.io/references/cli.html).

```
cd friendica-docker-image

cloudron build
cloudron install
```

## Usage

Use `cloudron push` to copy files into `/app/data/public/` and `cloudron exec` to get a remote terminal.

See https://cloudron.io/references/cli.html for how to get the `cloudron` command line tool.

## Tests

* Put `HashKnownHosts no` in your `~/.ssh/config`
* cd test
* npm install
* USERNAME=<> PASSWORD=<> mocha --bail test.js

## Contributors

Thanks to @gramakri and @nebulade for providing the LAMP stack docker image this image is based on.
