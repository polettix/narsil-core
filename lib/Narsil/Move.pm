package Narsil::Move;

use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );

use Moo;
extends 'Narsil::Object';

has matchid  => (is => 'ro', required => 1);
has userid   => (is => 'ro', required => 1);
has contents => (is => 'ro', required => 1);
has phase    => (
   is  => 'rw',
   isa => sub {
      die "invalid phase $_[0]"
        unless grep { $_[0] eq $_ } qw< pending rejected accepted >;
   },
   builder => 'BUILD_phase',
   default => sub { 'pending' },
);
has message => (is => 'rw', builder => 'BUILD_message', lazy => 1);
has match_status_before =>
  (is => 'rw', builder => 'BUILD_match_status_before', lazy => 1);
has match_phase_before =>
  (is => 'rw', builder => 'BUILD_match_phase_before', lazy => 1);
has match_status_after =>
  (is => 'rw', builder => 'BUILD_match_status_after', lazy => 1);
has match_phase_after =>
  (is => 'rw', builder => 'BUILD_match_phase_after', lazy => 1);

sub BUILD_phase               { return 'pending' }
sub BUILD_message             { return '' }
sub BUILD_match_status_before { return '' }
sub BUILD_match_phase_before { return '' }
sub BUILD_match_status_after  { return '' }
sub BUILD_match_phase_after  { return '' }

sub plain {
   my $self   = shift;
   my @fields = qw< id matchid userid contents phase message match_status_before match_phase_before match_status_after match_phase_after >;
   my %retval = map { $_ => $self->$_() } @fields;
   return \%retval;
} ## end sub to_hash

sub match {
   my $self = shift;
   return $self->model()->get_match($self->matchid());
}

sub game {
   my $self = shift;
   return $self->match()->game();
}

sub user {
   my $self = shift;
   return $self->model()->get_user($self->userid());
}

sub match_status_before_for {
   my ($self, $userid) = @_;
   return $self->game()->status_for($userid, $self->match_status_before());
}

sub match_status_after_for {
   my ($self, $userid) = @_;
   return $self->game()->status_for($userid, $self->match_status_after());
}

sub contents_for {
   my ($self, $userid) = @_;
   return $self->game()->move_contents_for($userid, $self);
}

1;
__END__

