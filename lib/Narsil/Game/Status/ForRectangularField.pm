package Narsil::Game::Status::ForRectangularField;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;

use Moo::Role;

has field_size_x => (is => 'rw', required => 1);
has field_size_y =>
  (is => 'rw', lazy => 1, default => sub { return $_[0]->field_size_x() });

sub normalized_position {
   my ($self, $position) = @_;
   my ($x, $y) =
     ref($position)
     ? @$position
     : ($position =~ m{\A (\d+) : (\d+) \z}mxs);
   return unless defined $x;
   return unless $x >= 0 && $x < $self->field_size_x();
   return unless $y >= 0 && $y < $self->field_size_y();
   return "$x:$y";
} ## end sub normalized_position

1;
__END__

