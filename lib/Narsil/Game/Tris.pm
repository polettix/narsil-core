package Narsil::Game::Tris;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use JSON;
use Moo;

use Narsil::Match;

extends 'Narsil::Game';
with 'Narsil::Game::Role::Status';
with 'Narsil::Game::Role::TwoPlayers';

around create_match => sub {
   my ($original, $self, %params) = @_;
   $params{status} = $self->inflate(field_size_x => 3)->plain();
   $self->$original(%params);
};

sub full_line {
   my ($field, $target, $x, $dx, $y, $dy) = @_;

   # go to the line extreme
   while ($x >= 0 && $x <= 2 && $y >= 0 && $y <= 2) {
      $x -= $dx;
      $y -= $dy;
   }

   # last action put me out of line bounds, so I back up one step
   $x += $dx;
   $y += $dy;

   # now advance on the line until we can
   my $count = 0;
   for my $i (0 .. 2) {
      return if $x < 0 || $x > 2;
      return if $y < 0 || $y > 2;
      my $value = $field->get_at([$x, $y]);
      return unless defined $value;
      return unless $value eq $target;
      $x += $dx;
      $y += $dy;
   } ## end for my $i (0 .. 2)
   return 1;
} ## end sub full_line

sub check_winner_position {
   my ($field, $position) = @_;
   my ($x, $y) = split /:/, $position;
   my $target = $field->get_at($position);
 WINNER_FOUND:
   for my $dx (-1 .. 1) {
      for my $dy (-1 .. 1) {
         next if $dx == 0 && $dy == 0;
         if (full_line($field, $target, $x, $dx, $y, $dy)) {
            return 1;
         }
      } ## end for my $dy (-1 .. 1)
   } ## end for my $dx (-1 .. 1)
   return;
} ## end sub check_winner_position

sub calculate_move_application {
   my $self = shift;
   my ($match, $move, $status) = $self->validate(@_);

   # check that move is doable
   my $movedata = $move->contents();
   my $position = $status->normalized_position($movedata);
   die {reason => "invalid move $movedata"}
     unless defined $position;
   die {reason => "position $position is not free"}
     if defined $status->get_at($position);

   # perform move
   my $userid = $move->userid();
   $status->set_at($position, $userid);
   $status->to_next_player();
   $match->status($status->plain());

   if (check_winner_position($status, $position)) {
      $match->winners($userid);
      $match->phase('terminated');
   }

   return $match;
} ## end sub calculate_move_application

sub _test_status_for {
   my ($self, $userid, $status) = @_;
   $status = $self->inflate($status);
   for my $x (0 .. $status->field_size_x() - 1) {
      for my $y (0 .. $status->field_size_y() - 1) {
         (my $current = $status->get_at([$x, $y])) // next;
         $status->remove_at([$x, $y]) if $current ne $userid;
      }
   } ## end for my $x (0 .. $status...
   return $status->plain();
} ## end sub _test_status_for

1;
__END__

