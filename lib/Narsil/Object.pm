package Narsil::Object;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;

use Moo;

has id => (
   is        => 'rw',
   lazy      => 1,
   predicate => 'has_id',
   default   => sub { die 'bummer!', }
);

has model => (
   is => 'ro',
   required => 1,
   weak_ref => 1,
);

1;
__END__

