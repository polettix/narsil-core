package Narsil::Game::Field;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use 5.012;
use Moo;

has field => (is => 'rw', lazy => 1, builder => 'BUILD_field');
sub BUILD_field { return {} }

sub get {
   my ($self, $position) = @_;
   $position = $self->normalized_position($position)
      or die { reason => 'invalid position' };
   my $field = $self->field();
   return unless exists $field->{$position};
   return $field->{$position};
}

sub set {
   my ($self, $position, $item) = @_;
   $position = $self->normalized_position($position)
      or die { reason => 'invalid position' };
   $self->field()->{$position} = $item;
   return $item;
}

sub from_hash {
   my ($self, $args) = @_;
   my %args = %$args;
   my $class = delete($args{_class}) // $self;
   (my $package = $class . '.pm') =~ s{(?: :: | ')}{/}gmxs;
   require $package;
   return $class->new(%args);
}

sub to_hash {
   my ($self) = @_;
   my %retval = %$self;
   $retval{_class} = ref $self;
   return \%retval;
}

1;
__END__

