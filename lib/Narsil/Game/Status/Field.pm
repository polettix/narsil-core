package Narsil::Game::Status::Field;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use Storable qw< dclone >;
use 5.012;

use Moo::Role;
requires 'normalized_position';
has field => (is => 'rw', default => sub {{}}, coerce => sub {dclone($_[0])});

sub get_at {
   my ($self, $position) = @_;
   $position = $self->normalized_position($position)
      or die { reason => 'invalid position' };
   my $field = $self->field();
   return unless exists $field->{$position};
   return $field->{$position};
}

sub set_at {
   my ($self, $position, $item) = @_;
   $position = $self->normalized_position($position)
      or die { reason => 'invalid position' };
   $self->field()->{$position} = $item;
   return $item;
}

sub remove_at {
   my ($self, $position) = @_;
   $position = $self->normalized_position($position)
      or die { reason => 'invalid position' };
   delete $self->field()->{$position};
   return;
}

1;
__END__

