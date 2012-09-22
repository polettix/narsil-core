package Narsil::Game::Role::Status;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;

use Moo::Role;
use Narsil::Match;

sub inflate {
   my $self  = shift;
   my $class = ref($self) . '::Status';
   (my $package = $class . '.pm') =~ s{(?: :: | ')}{/}gmxs;
   require $package;
   return $class->new(@_);
} ## end sub inflate

sub validate {
   my ($self, $imatch, $move) = @_;
   my $match = Narsil::Match->new(%$imatch);

   my $userid = $move->userid();
   die {reason => 'user not allowed'}
     unless $match->is_participant($userid);
   die {reason => 'match is not active'}
     unless $match->is_active();

   my $status = $self->inflate($match->status());
   die {reason => "not user's turn"}
     unless $status->is_current_player($userid);

   die {reason => 'move out of sync'}
     unless $status->equivalent_to($move->match_status_before());

   return ($match, $move, $status);
} ## end sub status_check

1;
__END__

