package Narsil::Game::Fake;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use JSON;
use Moo;
extends 'Narsil::Game';

use Narsil::Match;

sub create_match {
   my ($self, %params) = @_;
   my $configuration = from_json($params{configuration} || '{"starter":100}');
   my $model = $self->model();
   my $match = Narsil::Match->new(
      model => $model,
      gameid => $self->id(),
      configuration => $configuration,
      status => $configuration->{starter},
      phase => 'gathering', # accept any match for this game
   );
   return $model->put($match);
}

sub calculate_move_application {
   my ($self, $imatch, $move) = @_;
   my $match = Narsil::Match->new(%$imatch);

   die { reason => 'user not allowed' }
      unless $match->is_participant($move->userid());

   die { reason => 'match is not active' }
      unless $match->is_active();

   my $status = $match->status();
   my $movedata = $move->contents();

   # check that move applies to match
   die { reason => 'move out of sync' }
      unless $status == $move->match_status_before();

   # check that move is doable
   die { reason => 'inapplicable move' }
      unless $movedata > 0 && $status >= $movedata;

   # perform move
   $status -= $movedata;
   $match->status($status);
   $match->phase('terminated') unless $status; 
   return $match;
}

sub calculate_join_application {
   my ($self, $imatch, $join) = @_;
   my $match = Narsil::Match->new(%$imatch);
   
   die { reason => 'not accepting players' }
      unless $match->is_gathering();

   $match->add_participant($join->userid());
   $match->phase('active');

   return $match;
}


1;
__END__

