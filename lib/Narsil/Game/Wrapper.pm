package Narsil::Game::Wrapper;

use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );
use Try::Tiny;
use Moo;

extends 'Narsil::Game';
has instance =>
  (is => 'ro', lazy => 1, builder => 'BUILD_instance', weak_ref => 1);

sub BUILD_instance {
   my ($self) = @_;
   my $class = $self->class();
   (my $package = $class . '.pm') =~ s{::}{/}gmxs;
   require $package;
   return $package->new($self);
} ## end sub BUILD_instance

sub join {
   my $self = shift;
   return $self->instance()->join(@_);
}

sub move {
   my $self = shift;
   return $self->instance()->move(@_);
}

sub calculate_move_application {
   my $self = shift;
   return $self->instance()->calculate_move_application(@_);
}

1;
__END__

