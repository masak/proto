use strict;
use Module::Build;

my $build = Module::Build->new(
    dist_name          => 'perl6.modules.org',
    dist_author        => 'Perl 6 Hackers',
    license            => 'perl',
    create_makefile_pl => 'passthrough',

    dist_version => '0.1',

    # and now the list of perl module dependencies
    requires => {
        'CGI'             => 0,
        'HTML::Template'  => 0,
        'Mojolicious'     => 0,
        'YAML'            => 0,
        'File::Slurp'     => 0,
        'File::Path'      => 0,
        'JSON'            => 0,
        'IO::Socket::SSL'                => '1.94',
        'File::Spec::Functions'          => 0,
        'Mojolicious::Plugin::AssetPack' => '0.68',
        'Imager::File::PNG'              => '0.92',
        'Time::Moment'                   => '0.36',

        ## Required by the Mojo app:
          'Carp' => 0,
          'DBIx::Class::Candy'  => '0.005000',
          'DBIx::Class::Schema' => 0,
          'File::Spec' => 0,
          'File::Spec::Functions' => 0,
          'File::Temp' => 0,
          'FindBin' => 0,
          'IO::Handle' => 0,
          'IPC::Open3' => 0,
          'Import::Into' => 0,
          'Mojo::Base' => 0,
          'Mojo::Collection' => 0,
          'Mojo::SQLite' => 0,
          'Mojo::URL' => 0,
          'Mojo::Util' => 0,
          'Mojolicious' => '6.30',
          'Mojolicious::Commands' => 0,
          'Mojolicious::Plugin::AssetPack' => '0.68',
          'Mojolicious::Plugin::Bootstrap3' => '3.3505',
          'POSIX' => 0,
          'Test::Mojo::Role::Debug' => '1.003003',
          'Test::Mojo::Role::ElementCounter' => '1.001005',
          'Test::Mojo::Role::SubmitForm' => '1.001007',
          'Test::Mojo::WithRoles' => 0,
          'Test::More' => 0,
          'Test::Most' => 0,
          'SQL::Translator' => '0.11021',
          'base' => 0,
          'blib' => '1.01',
          'constant' => 0,
          'experimental' => 0,
          'strict' => 0,
          'strictures' => 2,
          'warnings' => 0
    }
);
$build->create_build_script;
