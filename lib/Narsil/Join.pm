package Narsil::Join;

use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );

use Moo;
extends 'Narsil::Object';

has matchid => (is => 'ro', required => 1);
has userid  => (is => 'ro', required => 1);
has phase => (
   is => 'rw',
   isa => sub {
      die "invalid phase $_[0]"
         unless grep { $_[0] eq $_ } qw< pending rejected accepted >;
   },
   builder => 'BUILD_phase',
   default => sub { 'pending' },
);
has message => (is => 'rw', builder => 'BUILD_message', lazy => 1);

sub BUILD_phase { return 'pending' }
sub BUILD_message { return '' }

sub match {
   my $self = shift;
   return $self->model()->get_match($self->matchid());
}

sub user {
   my $self = shift;
   return $self->model()->get_user($self->matchid());
}

sub plain {
   my $self   = shift;
   my @fields = qw< id matchid userid phase message >;
   my %retval;
   @retval{@fields} = @{$self}{@fields};
   return %retval if wantarray();
   return \%retval;
}


1;
__END__

