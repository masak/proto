package ModulesPerl6;

use File::Spec::Functions qw/catfile/;
use FindBin; FindBin->again;
use constant SECRETS_FILE => $ENV{MODULESPERL6_SECRETS}
                                // catfile $FindBin::Bin, '..', 'secrets';
use Mojo::Base 'Mojolicious';
use File::Glob qw/bsd_glob/;
use Mojo::File qw/path/;
use ModulesPerl6::Model::BuildStats;
use ModulesPerl6::Model::Dists;
use ModulesPerl6::Model::SiteTips;
use ModulesPerl6::SpriteMaker;
use experimental 'postderef';

sub startup {
    my $self = shift;

    # SETUP
    $self->plugin('Config');
    $self->moniker('ModulesPerl6');
    $self->plugin('PODRenderer') if $self->mode eq 'development';
    unshift $self->static->paths->@*, $ENV{MODULESPERL6_EXTRA_STATIC_PATH}
        if length $ENV{MODULESPERL6_EXTRA_STATIC_PATH};

    unless (-r SECRETS_FILE) {
        $self->app->log->info("Did not find secrets file at " . SECRETS_FILE);
        die 'Refusing to start without proper secrets'
            if $self->mode eq 'production';
    }
    $self->secrets([
        -r SECRETS_FILE ? path(SECRETS_FILE)->slurp : 'Perl 6 is awesome!'
    ]);

    # ASSETS
    $self->plugin( AssetPack => { pipes => [qw/Sass JavaScript Combine/] });
    $self->asset->process('app.css' => qw{
        https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css
        /sass/main.scss
    });

    for ( $self->static->paths->@* ) {
        next unless bsd_glob("$_/content-pics/dist-logos/*");
        ModulesPerl6::SpriteMaker->new->make_sprites(
            static_path => $_,
            pic_dir     => 'content-pics/dist-logos/',
            class       => 'dist-logos',
            image_file  => 'sprite.png',
            css_file    => 'sprite.css',
        );
        last;
    }

    $self->asset->process('app.js'  => qw{
        https://code.jquery.com/jquery-3.2.1.min.js
        https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js
        /js/main.js
    });

    # HELPERS
    $self->helper(lang_name => sub { "Perl\x{A0}6" });
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

    $r->any(['BREW'] => '/*coffee' => { coffee => '' } => sub {
        shift->render(text => 'Short and stout', status => 418)
    });

    $r->get('/')->to('root#index')->name('home');
    $r->get($_)->to('root#search')->name('search')
        for '/search', '/s/#q', '/search/#q';
    $r->get($_)->to('root#search')->name('tag') for '/t/#tag', '/tag/#tag';

    $r->get($_)->to('root#lucky')->name('lucky') for '/l/#q', '/lucky/#q';



    $r->get('/dist/:dist')->to('root#repo' )->name('dist' );
    $r->get('/repo/:dist')->to('root#repo' )->name('repo' );
    $r->get('/total'     )->to('root#total')->name('total');
    $r->get('/help'      )->to('root#help' )->name('help');

    $r->get('/todo/:author')->to('todo#index', { author => '' })->name('todo');
}

1;

__END__

