package ModulesPerl6;

# TODO: figure out where to secretly store secrets file on the final server
use constant SECRETS_FILE => 'secrets';

use Mojo::Base 'Mojolicious';
use FindBin; FindBin->again;
use File::Spec::Functions qw/catfile/;
use Mojo::Util qw/slurp/;
use ModulesPerl6::Model::BuildStats;
use ModulesPerl6::Model::Dists;
use ModulesPerl6::Model::SiteTips;

sub startup {
    my $self = shift;

    # SETUP
    $self->plugin('Config');
    $self->moniker('ModulesPerl6');

    my $secrets_file = catfile $FindBin::Bin, '..', SECRETS_FILE;

    $self->app->log->info("Did not find secrets file at $secrets_file")
        unless -r $secrets_file;

    $self->secrets([
        -r $secrets_file ? slurp $secrets_file : 'Perl 6 is awesome!'
    ]);

    # ASSETS
    $self->plugin(bootstrap3 => theme =>
            { cerulean => 'https://bootswatch.com/cerulean/_bootswatch.scss' }
    );
    $self->asset('app.css' => qw{
        https://cdn.datatables.net/1.10.10/css/jquery.dataTables.min.css
        /sass/main.scss
    });
    $self->asset('sprite.css' => 'sprites:///content-pics/dist-logos');
    $self->asset('app.js'  => qw{
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

    # TODO: the /dist/ route currently redirects to rep, because we don't have
    # a proper dist page yet
    $r->get('/dist/:dist')->to('root#repo')->name('dist');
    $r->get('/repo/:dist')->to('root#repo')->name('repo');
    $r->get('/kwalitee/:dist')->to('root#kwalitee')->name('kwalitee');
    $r->get('/total')->to('root#total')->name('total');

    $r->any('/not_implemented_yet')
        ->to('root#not_implemented_yet')
        ->name('not_implemented_yet');
}

1;

__END__

=encoding utf8

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

=head1 CONTACT INFORMATION

Original version of this module was written by Zoffix Znet
(L<https://github.com/zoffixznet/>, C<Zoffix> on irc.freenode.net).

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
