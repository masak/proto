package ModulesPerl6;

# TODO: figure out where to secretly store secrets file on the final server
use constant SECRETS_FILE => '/tmp/secrets';

use Mojo::Base 'Mojolicious';

use Mojo::Util qw/slurp/;
use ModulesPerl6::Model::Dists;
use ModulesPerl6::Model::BuildStats;

sub startup {
    my $self = shift;

    # SETUP
    $self->config(hypnotoad => {listen => ['http://*:3333']});
    $self->moniker('ModulesPerl6');
    $self->secrets([
        -r SECRETS_FILE ? slurp SECRETS_FILE : 'Perl 6 is awesome!'
    ]);

    # ASSETS
    $self->plugin(bootstrap3 =>
        theme => { cerulean => 'https://bootswatch.com/cerulean/_bootswatch.scss' }
    );
    $self->asset('app.css' => '/sass/main.scss');
    $self->asset('app.js'  => '/js/main.js'    );

    # HELPERS
    $self->helper( dists => sub {
        state $dists = ModulesPerl6::Model::Dists->new;
    });
    $self->helper( build_stats => sub {
        state $stats = ModulesPerl6::Model::BuildStats->new;
    });
    $self->helper( items_in => sub {
        my ( $c, $what ) = @_;
        return unless defined $what;
        $what = $c->stash($what) // [] unless ref $what;
        return @$what;
    });

    # ROUTES
    my $r = $self->routes;
    $r->get('/'          )->to('root#index');
    $r->get('/q/:term'   )->to('root#index');
    $r->get('/dist/:dist')->to('root#dist')->name('dist');
    $r->get('/kwalitee/:dist')->to('root#kwalitee')->name('kwalitee');

    $r->any('/NIY')->to('root#NIY')->name('NIY');
}

1;

# ABSTRACT: make dzil happy
