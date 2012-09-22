package Narsil::User;

use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );

use Moo;
extends 'Narsil::Object';

has id => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);

sub plain {
   my $self   = shift;
   my @fields = qw< id password >;
   my %retval;
   @retval{@fields} = @{$self}{@fields};
   return %retval if wantarray();
   return \%retval;
}


1;
__END__

