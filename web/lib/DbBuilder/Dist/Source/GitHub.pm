package DbBuilder::Dist::Source::GitHub;

use strictures 2;
use base 'DbBuilder::Dist::Source';

use Carp       qw/croak/;
use Mojo::Util qw/slurp  decode/;
use Pithub;

use DbBuilder::Log;

use Moo;
use namespace::clean;

has _repo => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        my ( $user, $repo ) = $self->_meta_url =~ $self->re;
        return Pithub->new->repos->get( user => $user, repo => $repo );
    },
);

has _token => (
    is => 'lazy',
    default => sub {
        my $file = $ENV{MODULES_PERL6_GITHUB_TOKEN_FILE};
        -r $file or log fatal => "GitHub token file [$file] is missing "
                            . 'or has no read permissions';
        return decode 'utf8', slurp $file;
    },
);

sub re { qr{^https?://\Qraw.githubusercontent.com\E/([^/]+)/([^/]+)}i }
sub load {
    my $self = shift;

    my $dist = $self->_parse_meta( $self->_download_meta );

    return $self->_fill_missing( $dist );
}

1;