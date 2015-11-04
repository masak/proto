# modules.perl6.org

These are the scripts to generate the website on http://modules.perl6.org/.

This directory now lives in the root directory of the gh-pages branch, and will probably be removed soon.

## Development

Please use the following steps to aid you in your development:
- Create a token with access to public repositories. To run the scripts, you need a [GitHub token](https://github.com/blog/1509-personal-api-tokens) with rights to query Perl 6 module GitHub repository information.

- Save the token in file named 'github-token' in `web` folder

- Install prerequisites for build script:
  ```
$ perl Build.PL
$ ./Build installdeps
```

- Run build script
```
$ cd web
$ perl build-project-list.pl --limit=<number-of-modules>
```

## Cron job

Once committed, the cron job will pick up your changes on the 20th and 50th minutes of every hour. The script can take up to 10 minutes to complete.

## Author

Intial version contributed by patrickas++ on #perl6

## License

Artistic License 2.0
