# Deployment and Development Instructions for Modules.Perl6.Org Website

*Note: these instructions are for Debian Linux*

# TABLE OF CONTENTS
  - [The Basics](#the-basics)
  - [Installing Required Software](#installing-required-software)
          - [SASS](#sass)
          - [Sprites](#sprites)
  - [Clone The Repository](#clone-the-repository)
          - [Install Perl 5 module dependencies:](#install-perl-5-module-dependencies)
      - [Production Deployment](#production-deployment)
  - [Generating The Database](#generating-the-database)
  - [Launching Development Server](#launching-development-server)
  - [Secrets](#secrets)
  - [Production Deployment Setup](#production-deployment-setup)
  - [Documentation](#documentation)
  - [More](#more)
  - [Troubleshooting](#troubleshooting)

## The Basics

Assuming a virginal Debian install, you first need to setup a recent Perl 5
version. The best approach is to use Perlbrew so as not to mess with your
system Perl 5. We'll need build tools and we'll also need `git` afterwards:

```bash
$ sudo apt-get install build-essential git curl;
$ \curl -L http://install.perlbrew.pl | bash;
```

Follow the instructions from Perlbrew's installation. Likely, you'll be asked
to add `source ~/perl5/perlbrew/etc/bashrc` to one of your bash files. Adding
it to the end of `~/.bashrc` is totally fine.

Now, install modern Perl 5:
```bash
$ perlbrew available
perl-5.22.0
...
...
```
Pick the latest available `perl` and run (substituting `perl-5.24.0` for
the latest version you see available):

```bash
$ perlbrew install perl-5.24.0`
```

Now, run `perlbrew switch perl-5.24.0` to switch to that version of Perl 5.

We'll also need [cpanm](metacpan.org/pod/App::cpanminus) and a
module, so run this next:

```bash
$ perlbrew install-cpanm;
$ cpanm Module::Build;
```

You now have Perl 5!

## Installing Required Software

A couple of Perl 5 modules need additional software to function:

#### SASS

```bash
$ sudo apt-get install ruby-sass
```

The [AssetPack plugin](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack)
converts [SASS](http://sass-lang.com/) into plain CSS. There are several
options to make it function properly. The `ruby-sass` package should work,
but might offer an older `sass`, which might be missing new features.
[CSS::Sass](https://metacpan.org/pod/CSS::Sass) Perl 5 module can be installed
instead, but it similarly might lag behind the newest `sass`. Lastly,
You can use Ruby's package manager to install most recent sass:

```bash
$ sudo apt-get install rubygems
$ sudo gem install sass
```

At the time of this writing, `ruby-sass` package works fine.

#### Sprites

```bash
$ sudo apt-get install libpng12-dev
```

The [AssetPack plugin](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack)
merges some of the images into a
[CSS Sprite](https://en.wikipedia.org/wiki/Sprite_%28computer_graphics%29#Sprites_by_CSS) using its
[sprite handler](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack::Handler::Sprites). It needs
`libpng12-dev` library to function

## Clone The Repository

```bash
$ git clone https://github.com/perl6/modules.perl6.org/
$ cd modules.perl6.org;
```

#### Install Perl 5 module dependencies:

```bash
$ cpanm --installdeps -vn .
```

### Production Deployment

If you're looking to deploy the app, you may wish to install *nginx*,
*Apache*, or other web server capable of reverse-proxying (if you don't want
to use [Mojolicious](http://mojolicio.us/)'s server).


## Generating The Database

Run the `build-project-list.pl` build script that will generate the SQLite database file. If you want it to also start the app in production mode, pass
`--restart-app` option. (you may also use the `--limit=` parameter so you don't build info for all the dists):
```bash
$ perl build-project-list.pl --limit=10
```

## Launching Development Server

Simply launch the `morbo` script. The server will be launched to listen on port `3333`:
```bash
$ ./morbo
Server available at http://127.0.0.1:3333
```

## Secrets

You don't really need to worry about this in ***development*** setup.
Mojolicious [uses this string to sign the session cookie with](https://metacpan.org/pod/Mojolicious#secrets). Create a file named `secrets` and write a
secret string into it. If file doesn't exist, string `Perl 6 is awesome!` will
be used, which is known to the world and thus is not secure.

## Production Deployment Setup
The `build-project-list.pl` build script launches the app automatically on port `3333`. You can also launch it yourself:
```
$ hypnotoad bin/ModulesPerl6.pl
```
You can specify a different port to use in the `modules_perl6.conf` configuration file on the `hypnotoad => {listen => ['http://*:3333']}` line.

There's nothing stopping you from using port `80`, but it's common to use another webserver that will reverse-proxy your requests. Here is how you would do that for *Apache* server:

1) Create file `/etc/apache2/sites-available/YOUR-HOST-OR-NAME-OF-SITE.conf`
2) Add `Proxy` instructions into it (note: you may need to [enable an appropriate proxy module in Apache](https://www.google.ca/?q=apache+enable+proxy+mod)):
```apache
<VirtualHost *:80>
  ServerName YOUR-HOST-OR-NAME-OF-SITE.com
  <Proxy *>
    Order deny,allow
    Allow from all
  </Proxy>
  ProxyRequests Off
  ProxyPreserveHost On
  ProxyPass / http://localhost:3333/ keepalive=On
  ProxyPassReverse / http://localhost:3333/
  RequestHeader set X-Forwarded-Proto "http"
</VirtualHost>
```
3) Enable this site:
```bash
$ sudo a2ensite YOUR-HOST-OR-NAME-OF-SITE
Enabling site YOUR-HOST-OR-NAME-OF-SITE.
```
4) Restart *Apache*:
```bash
$ sudo service apache2 reload
[ ok ] Reloading web server config: apache2.
```
## Documentation
The modules in this distribution contain embedded POD documentation. To read it, you can use the `perldoc` command. E.g.:
```bash
$ perldoc lib/ModulesPerl6/Model/Dists.pm
```

In `development` [mode](https://metacpan.org/pod/Mojolicious#mode)
(e.g. run with `morbo` script), you can also view the
documentation in your browser using the `/perldoc/` URL, e.g.
L<http://localhost:3333/perldoc/ModulesPerl6::Model::Dists>

## More

For alternative deployment methods, see http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#DEPLOYMENT

## Troubleshooting

If you're deploying in production and you receive `Service Not Available`
error from Apache:
  1. Check `hypnotoad` is actually running. You can do that by running
    `ps ax | grep ModulesPerl6` and seeing whether the app is in the list
    1. If it is, wait a minute or two. Sometimes the browser caches the
      response and still displays the message even if Apache is now serving
      the content
  2. Check that the proxy has been configured to listen to the correct port
    specified in the app config. Currently, that's `:3333`
