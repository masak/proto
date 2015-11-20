# Deployment and Development Instructions for Modules.Perl6.Org Website

*Note: these instructions are for Debian Linux*

## The Basics

Assuming a virginal Debian install, you first need to setup a recent Perl 5
version. The best approach is to use Perlbrew so as not to mess with your
system Perl 5. We'll need build tools and we'll also need `git` afterwards:

```bash
sudo apt-get install build-essential git curl;
\curl -L http://install.perlbrew.pl | bash;
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
Pick the latest available `perl` and run (substituting `perl-5.22.0` for
the latest version you see available):

```bash
perlbrew install perl-5.22.0`
```

Now, run `perlbrew switch perl-5.22.0` to switch to that version of Perl 5.

We'll also need [cpanm](metacpan.org/pod/App::cpanminus) and a
module, so run this next:

```bash
perlbrew install-cpanm;
cpanm Module::Build;
```

You're all set!.


## Clone The Repo

These instructions assume you are in the `mojo-app` directory of the
[repository](https://github.com/perl6/modules.perl6.org/):
```bash
git clone https://github.com/perl6/modules.perl6.org/
cd modules.perl6.org;
```

## Installing Required Software

A couple of Perl 5 modules need additional software to function:

#### SASS

```bash
  sudo apt-get install ruby-sass
```

The [AssetPack plugin](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack)
converts [SASS](http://sass-lang.com/) into plain CSS. There are several
options to make it function properly. The `ruby-sass` package should work,
but might offer an older `sass`, which might be missing new features.
[CSS::Sass](https://metacpan.org/pod/CSS::Sass) Perl 5 module can be installed
instead, but it similarly might lag behind the newest `sass`. Lastly,
You can use Ruby's package manager to install most recent sass:

```bash
  sudo apt-get install rubygems
  sudo gem install sass
```

At the time of this writing, `ruby-sass` package works fine.

#### Sprites

```bash
  sudo apt-get install libpng12-dev
```

The [AssetPack plugin](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack)
merges some of the images into a
[CSS Sprite](https://en.wikipedia.org/wiki/Sprite_%28computer_graphics%29#Sprites_by_CSS) using its
[sprite handler](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack::Handler::Sprites). It needs
`libpng12-dev` library to function

#### Install Perl 5 module dependencies:

```bash
$ perl Build.PL
$ ./Build installdeps
```

If asked whether to configure stuff automatically, just respond with `yes`.

### Production Deployment

If you're looking to deploy the app, you may wish to install *nginx*,
*Apache*, or other web server capable of reverse-proxying (if you don't want
to use [Mojolicious](http://mojolicio.us/)'s server).


## Generating The Database

Run the `build-project-list.pl` build script that will generate the SQLite database file and launch the app in production mode. If you
want to launch the app yourself, specify `--no-app-start` flag (you may also use the `--limit=` parameter so you don't build info for all the dists):
```bash
perl build-project-list.pl --no-app-start --limit=10;
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
hypnotoad bin/ModulesPerl6.pl
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
perldoc lib/ModulesPerl6/Model/Dists.pm
```

## More

For alternative deployment methods, see http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#DEPLOYMENT
