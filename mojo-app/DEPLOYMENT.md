# Deployment and Development Instructions for Modules.Perl6.Org Website

*Note: these instructions are for Debian Linux*

These instructions assume you are in the `mojo-app` directory of the [repository](https://github.com/perl6/modules.perl6.org/):
```bash
git clone https://github.com/perl6/modules.perl6.org/
cd modules.perl6.org/mojo-app;
```


## Installing Required Software

Install Perl 5 module dependencies:
```bash
$ perl Build.PL
$ ./Build installdeps
```

### Production Deployment

If you're looking to deploy the app, you may wish to install *nginx*, *Apache*, or other web server capable of reverse-proxying (if you don't want to use [Mojolicious](http://mojolicio.us/)'s server).


## Generating The Database

Run the `../db-builder/build-project-list.pl` build script that will generate the SQLite database file and launch the app in production mode. If you
want to launch the app yourself, specify `--no-app-start` flag (you may also use the `--limit=` parameter so you don't build info for all the dists):
```bash
cd ../db-builder/;
perl build-project-list.pl --no-app-start --limit=10;
cd ../mojo-app/;
```


## Launching Development Server

Simply launch the `morbo` script. The server will be launched to listen on port `3333`:
```bash
$ ./morbo
Server available at http://127.0.0.1:3333
```

## Secrets

You don't really need to worry about this in ***development*** setup. Mojolicious [uses this string to sign the session cookie with](https://metacpan.org/pod/Mojolicious#secrets). Create a file named `secrets` and write a secret string into it. If that file doesn't exist, the app will attempt to use the `github-token`
file in the `../db-builder/` directory. If that fails as well, string `Perl 6 is awesome!` will be used, which is known to the world and thus is not secure.


## Production Deployment Setup
The `../db-builder/build-project-list.pl` build script launches the app automatically on port `3333`. You can also launch it yourself:
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
