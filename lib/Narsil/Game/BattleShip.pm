package Narsil::Game::BattleShip;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use JSON;
use Moo;
use Narsil::Game::BattleShip::Status;

use Narsil::Match;

extends 'Narsil::Game';
with 'Narsil::Game::Role::Status';
#with 'Narsil::Game::Role::TwoPlayers';

around create_match => sub {
   my ($original, $self, %params) = @_;
   my $cfg =
     $params{configuration}
     ? decode_json($params{configuration})
     : {};
   $cfg->{size}  //= 10;
   $cfg->{boats} //= {
      due     => [qw< 0:0 1:0 >],
      tre_1   => [qw< 0:0 1:0 2:0 >],
#      tre_2   => [qw< 0:0 1:0 2:0 >],
#      quattro => [qw< 0:0 1:0 2:0 3:0 >],
#      cinque  => [qw< 0:0 1:0 2:0 3:0 4:0 >],
   };
   $cfg->{'multiple-turns'} //= 1;
   $params{configuration}   = $cfg;
   $params{status}          = $self->inflate(
      field_size_x   => $cfg->{size},
      allowed_boats  => $cfg->{boats},
      multiple_turns => $cfg->{'multiple-turns'},
   )->plain();
   $self->$original(%params);
};

sub calculate_join_application {
   my ($self, $imatch, $join) = @_;
   my $match = Narsil::Match->new(%$imatch);

   die {reason => 'not accepting players'}
     unless $match->is_gathering();

   my $userid = $join->userid();
   if (!$match->is_participant($userid)) {
      $match->add_participant($userid);
      $match->add_mover($userid); # Users are allowed to setup early
      my @participants = $match->participants();
      if (scalar(@participants) == 2) {
         $match->phase('active');
      } ## end if (scalar(@participants...
   } ## end if (!$match->is_participant...
   
   return $match;
} ## end sub calculate_join_application

sub add_boat {
   my ($self, $status, $move) = @_;
   die {reason => 'playing, cannot change boat setup'}
     unless $status->is_setup();
   $status->add_boat($move->{userid}, $move);
   return;
} ## end sub add_boat

sub remove_boat {
   my ($self, $status, $move) = @_;
   die {reason => 'playing, cannot change boat setup'}
     unless $status->is_setup();
   $status->remove_boat($move->{userid}, $move->{position});
   return;
} ## end sub remove_boat

sub setup_complete {
   my ($self, $status, $move, $match) = @_;
   die {reason => 'playing, cannot change boat setup'}
     unless $status->is_setup();
   my $userid = $move->{userid};
   die {reason => 'player has not placed all boats'}
     unless $status->has_all_boats($userid);

   # This user cannot move any more during setup, check for others
   Dancer::warning "removing user $userid from movers";
   $match->remove_mover($userid);
   Dancer::warning "movers: " . join(" ", $match->movers());
   return if $match->movers();

   # OK, here's time to play
   $status->to_play();

   # Set the first player to move and exit
   my ($first_player) = $match->participants();
   $match->movers($first_player); # only one mover from now on

   # Set # of turns
   my $turns =
       $status->multiple_turns()
     ? $status->surviving_boats_for($first_player)
     : 1;
   $status->turns($turns);

   return;
} ## end sub setup_complete

sub fire {
   my ($self, $status, $move, $match) = @_;

   # Still setting up?
   die {reason => 'still in field setup, cannot fire'}
     unless $status->is_play();

   # Get coordinates to aim to
   (my $coordinates = $move->{position})
     // die {reason => 'undefined position for fire action'};

   # Get opponent's name to fire to the right field!
   my $opponent = $match->opponent($move->{userid});

   # Complete position depends on userid and coordinates
   (my $position = $status->normalized_position("$opponent:$coordinates"))
     // die {reason => "invalid fire at $coordinates"};

   # Check for duplicate moves, we're tracking!
   die {reason => "fire at $coordinates already tried"}
     if defined $status->get_at($position);

   # OK, can fire
   if (my $hit = $status->hits($opponent, $coordinates)) {    # got it!
      $status->set_at($position, 'hit');
      my $boat = $hit->{boat};
      $boat->{hit}{$coordinates} = delete $boat->{intact}{$coordinates};

      if (!$status->surviving_boats_for($opponent)) {
         $match->phase('terminated');
         $match->winners($move->{userid});
      }
   } ## end if (my $hit = $status->hits...
   else {    # if no $hit... water!
      $status->set_at($position, 'water');
   }

   my $last_moves = $status->last_moves();
   $last_moves = {user => $move->{userid}, moves => []}
     unless exists $last_moves->{user}
        && $last_moves->{user} eq $move->{userid};
   push @{$last_moves->{moves}}, $position;
   $status->last_moves($last_moves);

   # pass to the next player if applicable
   $status->consume_turn();
   if (!$status->turns()) {    # finished turns?
      $match->movers($opponent);
      my $turns =
          $status->multiple_turns()
        ? $status->surviving_boats_for($opponent)
        : 1;
      $status->turns($turns);
   } ## end if (!$status->turns())

   return;
} ## end sub fire

sub calculate_move_application {
   my $self = shift;
   my ($match, $move, $status) = $self->validate(@_);

   # perform move
   my $mdetails = decode_json($move->contents());
   $mdetails->{userid} = $move->userid();
   my $action = $mdetails->{action} // 'fire';
   (
      my $method = {
         'add-boat'       => 'add_boat',
         'remove-boat'    => 'remove_boat',
         'fire'           => 'fire',
         'setup-complete' => 'setup_complete',
        }->{$action}
   ) // die {reason => "invalid action $action"};
   $self->$method($status, $mdetails, $match);

   # prepare for next round, clean up and go away
   $match->status($status->plain());
   return $match;
} ## end sub calculate_move_application

sub status_for {
   my ($self, $userid, $status) = @_;
   return $self->inflate($status)->plain_for($userid);
}

1;
__END__

