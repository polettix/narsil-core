package Narsil::Game::BattleShip::Status;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use Storable qw< dclone >;
use Scalar::Util qw< refaddr >;
use List::MoreUtils qw< firstidx >;
use Moo;
extends 'Narsil::Game::Status';
with 'Narsil::Game::Status::Field';
with 'Narsil::Game::Status::RoundRobin';
with 'Narsil::Game::Status::Phases';

# Complete field management
has field_size_x => (is => 'rw', required => 1);
has field_size_y =>
  (is => 'rw', lazy => 1, default => sub { return $_[0]->field_size_x() });

sub normalized_position {
   my ($self, $position) = @_;
   my ($subfield, $x, $y) =
     ref($position)
     ? @$position
     : ($position =~ m{\A (.*?) : (\d+) : (\d+) \z}mxs);
   return unless defined $x;
   return unless $x >= 0 && $x < $self->field_size_x();
   return unless $y >= 0 && $y < $self->field_size_y();
   return "$subfield:$x:$y";
} ## end sub normalized_position

has last_moves => (
   is => 'rw',
   default => sub { {} },
);

has allowed_boats => (
   is      => 'rw',
   default => sub { {} },
);

# array of hashes, each representing a boat
# a boat has the following fields:
# intact: array of intact positions
# hit: array of hit positions
has boats => (
   is      => 'rw',
   default => sub { {} },
   #coerce  => sub { dclone($_[0]) },
);

has multiple_turns => (
   is => 'rw',
   default => sub { 0 },
);

sub has_all_boats {
   my ($self, $userid) = @_;
   my $have = scalar keys %{$self->boats()->{$userid}};
   my $can  = scalar keys %{$self->allowed_boats()};
   return $have == $can;
}

sub surviving_boats_for {
   my ($self, $userid) = @_;
   my $boats = $self->boats()->{$userid};
   return grep { scalar keys %{$boats->{$_}{intact}} } keys %$boats;
} ## end sub surviving_boats_for

sub hits {
   my ($self, $userid, $position) = @_;
   $self->normalized_position("$userid:$position")
     // die {reason => "invalid position $position"};
   while (my ($boatid, $boat) = each %{$self->boats()->{$userid}}) {
      for my $status (qw< intact hit >) {
         for my $inp (keys %{$boat->{$status}}) {
            return {
               id              => $boatid,
               boat            => $boat,
               position_status => $status,
              }
              if $inp eq $position;
         } ## end for my $inp (@{$boat->{...
      } ## end for my $status (qw< intact hit >)
   } ## end for my $i (0 .. $#{$boats...
   return;
} ## end sub hits

sub expand_boat {
   my ($self, $boatid, $position, $orientation) = @_;
   my $template = $self->allowed_boats()->{$boatid};
   $self->normalized_position(":$position")
     // die {reason => "invalid position $position"};
   my ($x0, $y0) = split /:/, $position;
   return map {
      my ($x, $y) = split /:/;
      ($x, $y) =
          $orientation eq 'south' ? ($x0 + $y, $y0 - $x)
        : $orientation eq 'west'  ? ($x0 - $x, $y0 - $y)
        : $orientation eq 'north' ? ($x0 - $y, $y0 + $x)
        :                           ($x0 + $x, $y0 + $y);
      "$x:$y";
   } @$template;
} ## end sub expand_boat

sub add_boat {
   my ($self, $userid, $boatdef) = @_;

   my ($boatid, $position, $orientation) =
     @{$boatdef}{qw< id position orientation >};

   my $allowed_boats = $self->allowed_boats();
   die {reason => "invalid boat id " . $boatid // '*undef'}
     unless defined($boatid) && exists $allowed_boats->{$boatid};

   my $boats = $self->boats()->{$userid};
   die {reason => "boat $boatid already placed"}
     if defined $boats->{$boatid};

   die {reason => "invalid orientation $orientation"}
     unless grep { $orientation eq $_ } qw< north south east west >;

   my @positions =
     $self->expand_boat($boatid, $position, $orientation);

   for my $position (@positions) {
      die {reason => "position $position already occupied by another boat"}
        if $self->hits($userid, $position);
   }
   $self->boats()->{$userid}{$boatid} = {
      intact => { map { $positions[$_] => $_ } 0 .. $#positions },
      hit => {},
      id => $boatid,
      position => $position,
      orientation => $orientation,
   };
   return $self;
} ## end sub add_boat

sub active_boats_for {
   my ($self, $userid) = @_;
   return keys %{$self->boats()->{$userid}};
}

sub remove_boat {
   my ($self, $userid, $position) = @_;
   (my $hit = $self->hits($userid, $position))
     // die {reason => "no boat at position $position"};
   my $boats = $self->boats()->{$userid};
   delete $boats->{$hit->{id}};
   return $self;
} ## end sub remove_boat

sub plain_for {
   my ($self, $player) = @_;
   my $plain = dclone($self->plain());
   my $boats = delete $plain->{boats};
   $plain->{boats} = (defined $player && exists $boats->{$player}) ? $boats->{$player} : {};
   return $plain;
} ## end sub plain_for

1;
__END__
