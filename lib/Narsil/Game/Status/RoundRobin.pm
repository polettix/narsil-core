package Narsil::Game::Status::RoundRobin;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use Storable qw< dclone >;
use Moo::Role;

has players => (
   is      => 'rw',
   default => sub { [] },
   coerce => sub { dclone($_[0]) },
);

has current_player_id => (
   is      => 'rw',
   default => sub { 0 },
);

has turns => (
   is => 'rw',
   default => sub { 1 },
);

sub current_player {
   my $self    = shift;
   my $players = $self->players();
   return $players->[$self->current_player_id() % @$players];
}

sub is_current_player {
   my ($self, $target) = @_;
   return $target eq $self->current_player();
}

sub to_next_player {
   my $self = shift;
   $self->current_player_id(
      ($self->current_player_id() + 1) % @{$self->players()});
   $self->turns(@_) if @_;
}

sub consume_turn {
   my $self = shift;
   my $remaining = $self->turns() - 1;
   $remaining = 0 if $remaining < 0;
   $self->turns($remaining);
   return $remaining;
}

sub opponent {
   my ($self, $player) = @_;
   my $players = $self->players();
   die { reason => 'wrong number of players' }
      unless @$players == 2;
   return $player eq $players->[0] ? $players->[1] : $players->[0];
}

sub opponents {
   my ($self, $player) = @_;
   my @retval = grep { $player ne $_ } @{$self->players()};
   return @retval if wantarray();
   return \@retval;
}

1;
__END__

