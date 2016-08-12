package ModulesPerl6;

use File::Spec::Functions qw/catfile/;
use FindBin; FindBin->again;
use constant SECRETS_FILE => $ENV{MODULESPERL6_SECRETS}
                                // catfile $FindBin::Bin, '..', 'secrets';
use Mojo::Base 'Mojolicious';
use File::Glob qw/bsd_glob/;
use Mojo::Util qw/slurp/;
use ModulesPerl6::Model::BuildStats;
use ModulesPerl6::Model::Dists;
use ModulesPerl6::Model::SiteTips;
use experimental 'postderef';

sub startup {
    my $self = shift;

    # SETUP
    $self->plugin('Config');
    $self->moniker('ModulesPerl6');
    $self->plugin('PODRenderer') if $self->mode eq 'development';
    unshift $self->static->paths->@*, $ENV{MODULESPERL6_EXTRA_STATIC_PATH}
        if length $ENV{MODULESPERL6_EXTRA_STATIC_PATH};

    $self->app->log->info("Did not find secrets file at " . SECRETS_FILE)
        unless -r SECRETS_FILE;

    $self->secrets([
        -r SECRETS_FILE ? slurp SECRETS_FILE : 'Perl 6 is awesome!'
    ]);

    # ASSETS
    $self->plugin( AssetPack => { pipes => [qw/Sass JavaScript Combine/] });
    $self->asset->process('app.css' => qw{
        https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css
        https://cdn.datatables.net/1.10.10/css/jquery.dataTables.min.css
        /sass/main.scss
    });

    # $self->asset->process('sprite.css' => 'sprites:///content-pics/dist-logos')
    #     if map bsd_glob("$_/content-pics/dist-logos/*"),
    #         $self->static->paths->@*;

    $self->asset->process('app.js'  => qw{
        https://code.jquery.com/jquery-1.11.3.min.js
        https://cdn.datatables.net/1.10.10/js/jquery.dataTables.min.js
        /js/jquery-deparam.js
        /js/main.js
    });

    # HELPERS
    $self->helper( dists => sub {
        state $dists = ModulesPerl6::Model::Dists->new;
    });
    $self->helper( build_stats => sub {
        state $stats = ModulesPerl6::Model::BuildStats->new;
    });
    $self->helper( site_tips => sub {
        state $tips = ModulesPerl6::Model::SiteTips->new;
    });
    $self->helper( items_in => sub {
        my ( $c, $what ) = @_;
        return unless defined $what;
        $what = $c->stash($what) // [] unless ref $what;
        return @$what;
    });

    # ROUTES
    my $r = $self->routes;

    # multiple search aliases, because why not?
    $r->get( $_ )->to('root#index') for qw{/  /q/:q  /s/:q  /search/:q};

    # TODO: the /dist/ route currently redirects to repo, because we don't have
    # a proper dist page yet
    $r->get('/dist/:dist'    )->to('root#repo'    )->name('dist'    );
    $r->get('/repo/:dist'    )->to('root#repo'    )->name('repo'    );
    $r->get('/total'         )->to('root#total'   )->name('total'   );

    $r->any('/not_implemented_yet')
        ->to('root#not_implemented_yet')
        ->name('not_implemented_yet');
}

1;

__END__

=encoding utf8

=for stopwords md

=head1 NAME

ModulesPerl6 - Web app powering modules.perl6.org

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use FindBin;
    BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

    require Mojolicious::Commands;
    Mojolicious::Commands->start_app('ModulesPerl6');

=head1 DESCRIPTION

You would not use this module directly, but instead start your app
with a script.

See DEPLOYMENT.md file included with this distribution.

Also, you may wish to consult
L<http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#DEPLOYMENT>
for more details.

=head1 ENVIRONMENTAL VARIABLES

There are two environmental variables supported by the app that are used
by the test scripts.

=head2 C<MODULESPERL6_SECRETS>

Specifies the location of the secrets file.

=head2 C<MODULESPERL6_EXTRA_STATIC_PATH>

Specifies an additional directory to C<unshift> into
L<Mojolicious::Static/paths>.

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
