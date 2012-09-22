package Narsil::Game;

use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );
use Try::Tiny;
use Moo;
use 5.012;

extends 'Narsil::Object';

has name => (is => 'ro', required => 1);
has class => (is => 'ro', required => 1);

sub plain {
   my $self = shift;
   my @fields = qw< id name class >;
   my %retval;
   @retval{@fields} = @{$self}{@fields};
   return %retval if wantarray();
   return \%retval;
}

sub create_match {
   my ($self, %params) = @_;
   my $model = $self->model();
   my $match = Narsil::Match->new(
      model         => $model,
      creator       => $params{creator},
      gameid        => $self->id(),
      configuration => $params{configuration},
      status        => $params{status},
      phase         => $params{phase} // 'gathering',    # accept any match for this game
   ); 
   return $model->put($match);
} ## end sub create_match

sub join {
   my ($self, $match, $join) = @_;
   my $updated_match;
   $self->model()->locked_execute(
      $match,
      sub {
         my ($reloaded_match) = @_;
         $updated_match = $self->apply_join($reloaded_match, $join);
      },
   );
   return $self->model()->get(join => $join->id());
}

sub move {
   my ($self, $match, $move) = @_;
   my $updated_match;
   $self->model()->locked_execute(
      $match,
      sub {
         my ($reloaded_match) = @_;
         $updated_match = $self->apply_move($reloaded_match, $move);
      }
   );
   return $self->model()->get(move => $move->id());
}

sub apply_join {
   my ($self, $match, $join) = @_;
   my $model = $self->model();

   my $new_match;
   try {
      $new_match = $self->calculate_join_application($match, $join);
      $join->phase('accepted');
   }
   catch {
      $join->message($_);
      $join->phase('rejected');
   };
   $model->put($join);
   $model->put($new_match) if $new_match;

   return $new_match;
}

sub apply_move {
   my ($self, $match, $move) = @_;
   my $model = $self->model();

   my $new_match;
   try {
      $new_match = $self->calculate_move_application($match, $move);
      $move->phase('accepted');
      $move->match_status_after($new_match->status());
      $move->match_phase_after($new_match->phase());
   }
   catch {
      $move->message($_);
      $move->phase('rejected');
   };
   $model->put($move);
   $model->put($new_match) if $new_match;

   return $new_match;
}

sub calculate_move_application {
   my ($self, $match, $move) = @_;
   die 'unimplemented';
}

sub calculate_join_application {
   my ($self, $match, $join) = @_;
   die 'unimplemented';
}

sub status_for {
   my ($self, $userid, $status) = @_;
   return $status; # by default give back the whole status
}

sub move_contents_for {
   my ($self, $userid, $move) = @_;
   return $move->contents();
}

1;
__END__

