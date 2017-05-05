# Adapted from now deprecated Mojolicious::Plugin::AssetPack::Handler::Sprites
# Copyright (C) 2014, Jan Henning Thorsen
# Original can be found at  https://github.com/jhthorsen/mojolicious-plugin-assetpack/blob/f2a31c17d5076b056673f26dcb82071b505c9059/lib/Mojolicious/Plugin/AssetPack/Handler/Sprites.pm

package ModulesPerl6::SpriteMaker;
use File::Basename 'basename';
use File::Spec::Functions qw/catfile  catdir/;
use Imager::File::PNG;
use Mojo::Base -base;
use Mojo::File qw/path/;

sub make_sprites {
    my $self = shift;
    my %opts = @_;
    my $class = $opts{class};
    my $directory  = catdir  @opts{qw/static_path  pic_dir   /};
    my $image_file = catfile @opts{qw/static_path  image_file/};
    my $css_file   = catfile @opts{qw/static_path  css_file  /};

    my $tiled = Imager->new(xsize => 1000, ysize => 10000, channels => 4);
    my $css   = '';
    my @size  = (0, 0);

    die "Could not find sprites directory `$directory`" unless $directory;
    opendir my $SPRITES, $directory or die "opendir $directory: $!";

    for my $file (sort readdir $SPRITES) {
        next unless $file =~ /\.(jpe?g|png)$/i;
        my $tile = Imager->new(file => File::Spec->catfile($directory, $file))
            or die Imager->errstr;

        my $cn = $file;
        my ($w, $h) = ($tile->getwidth, $tile->getheight);
        $cn =~ s!\.\w+$!!;
        $cn =~ s!\W!-!g;
        $css .= ".$class.$cn { background-position: 0 -$size[1]px;"
                . " width: ${w}px; height: ${h}px; }\n";

        $tiled->paste(src => $tile, left => 0, top => $size[1])
            or die $tiled->errstr;
        $size[1] += $h;
        $size[0] = $w if $size[0] < $w;
    }

    $tiled->crop(right => $size[0], bottom => $size[1])
        ->write(data => \my $sprite, type => 'png')
            or die $tiled->errstr;

    $css .= ".$class { background: url(/$opts{image_file})"
            . " no-repeat; display: inline-block; }\n";
    path($image_file)->spurt($sprite);
    path(  $css_file)->spurt($css);
}

1;
