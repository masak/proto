package DbBuilder::Dist::Source::GitHub;

use strictures 2;
use base 'DbBuilder::Dist::Source';

use DbBuilder::Log;

use Moo;
use namespace::clean;

sub re { qr{^https?://\Qraw.githubusercontent.com\Q}i }
sub load {
    my $self = shift;

    my $dist = $self->_parse_meta( $self->_download_meta );
}