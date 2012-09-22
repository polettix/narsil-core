package Narsil::Game::Field::Rectangular;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;

use Moo;
extends 'Narsil::Game::Field';

has size_x => (is => 'ro', required => 1);
has size_y => (is => 'ro', lazy => 1, builder => 'BUILD_size_y');
sub BUILD_size_y { return $_[0]->size_x() }

sub normalized_position {
   my ($self, $position) = @_;
   my ($x, $y);
   if (ref $position) {
      ($x, $y) = @$position;
   }
   elsif ($position =~ m{\A (\d+) : (\d+) \z}mxs) {
      ($x, $y) = ($1, $2);
   }
   else {
      return;
   }
   return unless $x >= 0 && $x < $self->size_x();
   return unless $y >= 0 && $y < $self->size_y();
   return "$x:$y";
}

1;
__END__

