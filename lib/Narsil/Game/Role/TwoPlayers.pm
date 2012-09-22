package Narsil::Game::Role::TwoPlayers;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;

use Narsil::Match;

use Moo::Role;
requires 'inflate';

sub calculate_join_application {
   my ($self, $imatch, $join) = @_;
   my $match = Narsil::Match->new(%$imatch);

   die {reason => 'not accepting players'}
     unless $match->is_gathering();
   
   if (!$match->is_participant($join->userid())) {
      $match->add_participant($join->userid());
      my @participants = $match->participants();
      if (scalar(@participants) == 2) {
         $match->phase('active');
         my $status = $self->inflate($match->status());
         $status->players([@participants]);
         $match->status($status->plain());
      } ## end if (scalar(@participants...
   } ## end if (!$match->is_participant...
   
   return $match;
} ## end sub calculate_join_application


1;
__END__

