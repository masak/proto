package P6Project::SpriteMaker;

use Mojo::Base -base;

use Carp                  qw/croak          /;
use File::Copy            qw/copy           /;
use File::Find            qw/find           /;
use File::Temp            qw/tempdir        /;
use File::Spec::Functions qw/catdir  catfile/;
use Mojo::Util            qw/b64_encode     /;
use Mojolicious;

has 'css';

sub spritify {
    my $self = shift;
    my @ignore = @{ ref $_[-1] ? pop : [] };
    @_ or croak 'Missing list of paths to search for pictures';
    my $asset_dir = $self->_gather_pics( \@ignore, @_ );

    # Set up the app
    my $s = Mojolicious->new;
    $s->mode('production');
    $s->log->level('fatal'); # disable 'info' message from AssetPack
    $s->static->paths([ catdir $asset_dir, 'public' ]);

    # AssetPack plugin will generate the CSS and the Sprite image
    $s->plugin('AssetPack');
    $s->asset( 'app.css' => 'sprites:///sprite' );

    # Fetch CSS code and embed the sprite as base64 in it
    my $css = $s->static->file( $s->asset->get('app.css') )->slurp;
    my ( $sprite_filename )
    = $css =~ /\.sprite\{background:url\(  (sprite-\w+\.png)  \)/x;

    my $sprite = $s->static->file( catfile 'packed', $sprite_filename )->slurp;
    $sprite = b64_encode $sprite, '';

    $css =~ s{\Q$sprite_filename\E}{data:image/png;base64,$sprite};

    # Modify pic classnames to avoid potential clashes
    $css =~ s{\.sprite\.(?=[\w-]+)}{.sprite.s-}g;
    $self->css( $css );

    $self;
}

sub _gather_pics {
    my ( $self, $ignore, @locations ) = @_;

    my %ignore = map +( $_ => 1 ), @$ignore;
    my @pics = grep -f, @locations;
    find sub {
        return unless -f and /\.(png|gif|jpg|jpeg)$/ and not $ignore{$_};
        push @pics, $File::Find::name;
    }, grep -d, @locations;

    my $dir = tempdir CLEANUP => 1;
    mkdir catdir $dir, 'public';
    my $sprite_dir = catdir $dir, 'public', 'sprite';
    mkdir $sprite_dir
        or croak "Failed to create sprite dir [$sprite_dir]: $!";

    copy $_ => $sprite_dir for @pics;

    return $dir;
}

1;

__END__

=head1 SYNOPSIS

    P6Project::SpriteMaker->new->spritify('pics', 'pic1.png')->css;

=head1 DESCRIPTION

Generate a CSS sprite using given image files.

=head1 METHODS

=head2 C<new>

    my $s = P6Project::SpriteMaker->new;

Creates and returns a new C<P6Project::SpriteMaker> object. Takes no arguments.

=head2 C<spritify>

    $s->spritify( qw/list of dirs with pics or pics/ );
    $s->spritify( qw/list of dirs with pics or pics/, [qw/ignore these/] );

Returns its invocant. Takes a list of paths and searches them for pics to
use as sprites. The last element can be an arrayref, in which case, this
will be a list of filenames (no directory portion) that will be ignored.

Will croak if no paths are given or it has trouble
creating the temporary directory to assemble the sprite in.

=head2 C<css>

    say $s->css;

Returns CSS code of the sprite. Must be called after a call to L</spritify>

=end
