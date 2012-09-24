package Narsil::Match;
use strict;
use warnings;
use English qw< -no_match_vars >;
use Moo;
use Narsil::Move;
use Narsil::Join;
use 5.012;
use List::MoreUtils qw< any >;

extends 'Narsil::Object';

has gameid => (is => 'ro', required => 1);
has phase => (
   is  => 'rw',
   isa => sub {
      die "invalid phase $_[0]"
        unless grep { $_[0] eq $_ }
           qw< pending rejected gathering active terminated >;
   },
   builder => 'BUILD_phase',
   default => sub { 'pending' },
);

sub is_pending    { return $_[0]->phase() eq 'pending' }
sub is_rejected   { return $_[0]->phase() eq 'rejected' }
sub is_gathering  { return $_[0]->phase() eq 'gathering' }
sub is_active     { return $_[0]->phase() eq 'active' }
sub is_terminated { return $_[0]->phase() eq 'terminated' }

# Participation support
has creator => (is => 'ro', required => 1);
has _participants =>
  (is => 'rw', builder => 'BUILD_participants', lazy => 1);
has _invited => (is => 'rw', builder => 'BUILD_invited', lazy => 1);
has _winners => (is => 'rw', builder => 'BUILD_winners', lazy => 1);
has _join_ids => (
   is      => 'rw',
   builder => 'BUILD_joins',
   lazy    => 1,
   trigger => sub { $_[0]->clear_cache_joins() }
);
has _cache_joins => (
   is      => 'rw',
   builder => 'BUILD_cache_joins',
   lazy    => 1,
   clearer => 'clear_cache_joins'
);

# Opaque, game-specific data
has configuration =>
  (is => 'rw', builder => 'BUILD_configuration', lazy => 1);
has status => (is => 'rw', builder => 'BUILD_status', lazy => 1);
has _move_ids => (
   is      => 'rw',
   builder => 'BUILD_moves',
   lazy    => 1,
   trigger => sub { $_[0]->clear_cache_moves() }
);
has _cache_moves => (
   is      => 'rw',
   builder => 'BUILD_cache_moves',
   lazy    => 1,
   clearer => 'clear_cache_moves'
);
has origin =>
  (is => 'rw', lazy => 1, predicate => 'has_origin', weak_ref => 1);

sub BUILD_phase        { return 'pending' }
sub BUILD_participants { return [] }
sub BUILD_invited      { return {} }
sub BUILD_winners      { return [] }
sub BUILD_joins        { return [] }

sub BUILD_cache_joins {
   my ($self) = @_;
   my $model = $self->model();
   return [map { $model->get_join($_) } $self->join_ids()];
} ## end sub BUILD_cache_joins
sub BUILD_moves { return [] }

sub BUILD_cache_moves {
   my ($self) = @_;
   my $model = $self->model();
   return [map { $model->get_move($_) } $self->move_ids()];
} ## end sub BUILD_cache_moves
sub BUILD_configuration { return undef }
sub BUILD_status        { return undef }

sub status_for {
   my ($self, $userid) = @_;
   return $self->game()->status_for($userid, $self->status());
}

sub join_ids {
   my $self = shift;
   $self->_join_ids([@_]) if @_;
   return @{$self->_join_ids()};
}

sub joins {
   my $self = shift;
   $self->join_ids([map { $_->id() } @_]) if @_;
   return @{$self->_cache_joins()};
}

sub add_join {
   my ($self, $join) = @_;
   push @{$self->_join_ids()}, $join->id();
   $self->clear_cache_joins();
   return $self;
} ## end sub add_join

sub move_ids {
   my $self = shift;
   $self->_move_ids([@_]) if @_;
   return @{$self->_move_ids()};
}

sub moves {
   my $self = shift;
   $self->_move_ids([map { $_->id() } @_]) if @_;
   return @{$self->_cache_moves()};
}

sub add_move {
   my ($self, $move) = @_;
   push @{$self->_move_ids()}, $move->id();
   $self->clear_cache_moves();
   return $self;
} ## end sub add_move

sub plain {
   my $self = shift;
   my @fields =
     qw< id gameid phase creator configuration status _participants _invited _winners _join_ids _move_ids >;
   my %retval = map { $_ => $self->$_() } @fields;
   return %retval if wantarray();
   return \%retval;
} ## end sub plain

sub _flagify {
   map { $_ => 1 } @_;
}

sub participants {
   my $self = shift;
   my $p    = $self->_participants();
   @$p = [@_] if @_;
   return @$p;
} ## end sub participants

sub add_participant {
   my ($self, $userid) = @_;
   push @{$self->_participants()}, $userid;
   return $userid;
}

sub is_participant {
   my ($self, $user) = @_;
   my $id = ref $user ? $user->id() : $user;
   return any { $_ eq $id } $self->participants();
}

sub invited {
   my $self = shift;
   my $p    = $self->_invited();
   %$p = _flagify(@_) if @_;
   return keys %$p;
} ## end sub invited

sub is_invited {
   my ($self, $user) = @_;
   my $invited = $self->_invited();
   return 1 unless scalar keys %$invited;

   my $id = ref $user ? $user->id() : $user;
   return exists $invited->{$id};
} ## end sub is_invited

sub winners {
   my $self = shift;
   my $p    = $self->_winners();
   @$p = @_ if @_;
   return @$p;
} ## end sub winners

sub game {
   my $self = shift;
   return $self->model()->get_game($self->gameid());
}

# FIXME to design the right interactions for supporting atomic operations...

# We leave to the game implementation the decision of what to do and to command the right interactions with the model
sub join {
   my ($self, $userid) = @_;
   die {reason => 'not_allowed'} unless $self->is_invited($userid);

   my $model = $self->model();
   my $join  = Narsil::Join->new(
      model   => $model,
      matchid => $self->id(),
      userid  => $userid,
   );
   $model->put($join);

   $model->locked_execute(
      $self,
      sub {
         my ($latest) = @_;
         $latest->add_join($join);
         $model->put($latest);
         %$self = %$latest;
         return $latest;
      },
   );
   return $self->game()->join($self, $join);
} ## end sub join

sub move {
   my ($self, $userid, $movedata) = @_;

   # first of all, save the move
   my $model = $self->model();
   my $move  = Narsil::Move->new(
      model               => $model,
      matchid             => $self->id(),
      userid              => $userid,
      match_status_before => $self->status(),
      match_phase_before  => $self->phase(),
      contents            => $movedata,
   );
   $model->put_move($move);

   $model->locked_execute(
      $self,
      sub {
         my ($latest) = @_;
         $latest->add_move($move);
         $model->put($latest);
         %$self = %$latest;
         return $latest;
      },
   );

   # now try to use it
   return $self->game()->move($self, $move);
} ## end sub move

1;
