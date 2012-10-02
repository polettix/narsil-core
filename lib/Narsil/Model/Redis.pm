package Narsil::Model::Redis;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use Redis;
use Try::Tiny;
use Scalar::Util qw< blessed >;
use Storable qw< dclone >;
use JSON;
use Moo;
extends 'Narsil::Model';
use 5.012;

has redis => (
   is      => 'ro',
   default => sub { 'localhost:6379' },
   coerce  => sub {
      my $candidate = shift;
      return $candidate if blessed $candidate;
      my $ref = ref $candidate;
      return Redis->new(
           $ref eq '' ? (server => $candidate)
         : $ref eq 'HASH' ? %$candidate
         : @$candidate
      );
   },
);

sub create {
   my $package = shift;
   my %params = ref($_[0]) ? %{$_[0]} : @_;
   my $self = $package->new(redis => "$params{host}:$params{port}");
   $self->redis()->auth($params{password}) if exists $params{password};
   return $self;
}

sub raw_get {
   my ($self, $type, $id) = @_;
   my $value = $self->redis()->get("$type:$id") // 'undef';
   return decode_json($self->redis()->get("$type:$id"));
} ## end sub raw_get

sub next_id {
   my ($self, $type) = @_;
   return $self->redis()->incr("id:$type");
}

sub put {
   my ($self, $object) = @_;

   # Ensure object has an id
   my $type = $self->type_for($object);
   $object->id($self->next_id($type)) unless $object->has_id();

   # Check for overrides
   if (my $method = $self->can("_put_$type")) {
      return $self->$method($object);
   }

   # Save object
   $self->_put($type, scalar $object->plain());

   return $object;
} ## end sub put

sub _put {
   my ($self, $type, $plain) = @_;
   $self->redis()->set("$type:$plain->{id}", encode_json($plain));
   return;
}

sub _put_match {
   my ($self, $match) = @_;
   $self->_put('match', scalar $match->plain());
   my $redis = $self->redis();
   my $id    = $match->id();
   for my $userid ($match->participants()) {    # FIXME
      $redis->sadd("match:$id:participants", $userid);
      $redis->sadd("user:$userid:matches",   $id);
   }
   my $origin = $match->has_origin() ? $match->origin() : undef;
   if ($origin && $origin->phase() ne $match->phase()) {
      my $ophase = $origin->phase();
      $redis->srem('matches:phase:' . $origin->phase(), $id);
   }
   my $nphase = $match->phase();
   $redis->sadd('matches:phase:' . $match->phase(), $id);
   return $match;
} ## end sub _put_match

sub _disabled_put_match {
   my ($self, $match) = @_;
   my %match = %$match;
   delete $match{$_} for qw< model _cache_joins >;
   $self->_put(match => \%match);
   return $match;
} ## end sub _disabled_put_match

sub put_match { goto \&_put_match }

sub locked_execute {
   my ($self, $object, $op) = @_;
   my $id    = $object->id();
   my $type  = $self->type_for($object);
   my $key   = "$type:$id";
   my $redis = $self->redis();

   my $executed = 0;
   my $retval;
   while (!$executed) {

      # "lock"
      $redis->watch($key);
      my $latest = $self->get($type => $id);
      $latest->origin($object) if $latest->can('origin');
      $redis->multi();

      # call $op with updated match data
      try {
         $retval = $op->($latest);
         my @execution = $redis->exec();
         $executed = scalar @execution;
      }
      catch {
         my $exception = $_;
         $redis->discard();
         die($exception) if $exception;
      };
   } ## end while (!$executed)

   return $retval;
} ## end sub locked_execute

sub matches_id_for {
   my ($self, $phase, $userid) = @_;
   my $redis = $self->redis();
   return $redis->sinter("matches:phase:$phase", "user:$userid:matches")
      if defined $userid;
   return $redis->smembers("matches:phase:$phase")
}

sub games {
   my ($self) = @_;
   return grep { defined $_ } map {
      my $game;
      try {
         $game = $self->get_game($_)
      };
      $game;
   } $self->redis()->smembers('games');
} ## end sub games

sub users_id {
   return $_[0]->redis()->smembers('users');
}

sub users {
   my ($self) = @_;
   return map {
      $self->get_user($_);
   } $self->users_id();
}

1;
__END__

