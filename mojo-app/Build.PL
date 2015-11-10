use strict;
use Module::Build;

my $build = Module::Build->new(
    dist_name          => 'mojo-app::perl6.modules.org',
    dist_author        => 'Perl 6 Hackers',
    license            => 'perl',
    create_makefile_pl => 'passthrough',

    dist_version => '0.1',

    # and now the list of perl module dependencies
    requires => {
        'Mojolicious'     => '6.29',
        'Mojolicious::Plugin::AssetPack' => '0.68',
        'Mojolicious::Plugin::Bootstrap3' => '3.3505',
        'Package::Alias' => '0.13',
        'SQL::Translator' => '0.11021',
        'DBIx::Class' => '0.082820',
        'Test::Mojo::WithRoles' => '0.02',
        'Test::Mojo::Role::ElementCounter' => '1.001005',
        'Test::Mojo::Role::SubmitForm' => '1.001007',
    }
);
$build->create_build_script;
