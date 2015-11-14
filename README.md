# modules.perl6.org

These are the scripts to generate the website on http://modules.perl6.org/.

## Development

Please use the following steps to aid you in your development:
- Create a token with access to public repositories. To run the scripts, you need a [GitHub token](https://github.com/blog/1509-personal-api-tokens) with rights to query Perl 6 module GitHub repository information.

- Save the token in file named 'github-token' in `web` folder

- Install prerequisites for build script:
  ```
$ sudo apt-get install libpng12-dev
$ perl Build.PL
$ ./Build installdeps
```

- Run build script
  ```
$ cd web
$ perl build-project-list.pl --limit=<number-of-modules>
```
The build script automatically starts the Mojolicious app that powers the
front end. To disable that behaviour, specify the `--no-app-start` flag:

```bash
    $ perl build-project-list.pl --no-app-start>
```

## Seeing your changes

Once committed, the production cron job will pick up your changes on the 20th and 50th minutes of every hour. The script can take up to 10 minutes to complete.

```
20,50   *       *       *       *       sh update-modules.perl6.org > log/update.log 2>&1; cp log/update.log /var/www/modules.perl6.org/log
```

The cron job results can be found [here](http://modules.perl6.org/log/update.log).

## Author

Intial version contributed by patrickas++ on #perl6

## License

Artistic License 2.0
