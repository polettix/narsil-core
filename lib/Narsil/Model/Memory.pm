package Narsil::Model::Memory;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;

use Moo;
extends 'Narsil::Model';

has repository => (
   is      => 'ro',
   isa     => sub { die unless ref($_[0]) eq 'HASH' }
   default => sub {
      my $self = shift;
      require Narsil::Game::Fake;
      $self->put(
         Narsil::Game::Fake->new(
            model => $self,
            id    => 'fake',
            name  => 'Fake game for test purposes',
            class => 'Narsil::Game::Fake',
         )
      );
      require Narsil::Game::Tris;
      $self->put(
         Narsil::Game::Tris->new(
            model => $self,
            id    => 'tris',
            name  => 'Classic tris game',
            class => 'Narsil::Game::Tris',
         )
      );
      require Narsil::Game::BattleShip;
      $self->put(
         Narsil::Game::BattleShip->new(
            model => $self,
            id    => 'battleship',
            name  => 'Classic battleship game',
            class => 'Narsil::Game::BattleShip',
         )
      );
   },
);

has idgen => (
   is => 'rw',
   default => sub { return 0 },
);

sub next {
   my $self = shift;
   $self->idgen(my $id = $self->idgen() + 1);
   return $id;
}

sub raw_get {
   my ($self, $type, $id) = @_;
   return $self->repository()->{$type}{$id};
}

sub put {
   my ($self, $object) = @_;
   $object->id($self->next()) unless $object->has_id();
   $self->repository()->{$self->type_for($object)}{$object->id()} = $object;
   return $object;
}

sub locked_execute {
   my ($self, $match, $op) = @_;
   return $op->($self->get(match => $match->id()));
}

sub match_join { die 'still unimplemented...' }

1;
__END__

