package Narsil::Model;

use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );
use 5.012;
use Moo;

sub raw_get { my ($self, $type, $id) = @_; die 'unimplemented' }
sub get_match { my ($self, $id) = @_; return $self->get(match => $id); }
sub get_game { my ($self, $id) = @_; return $self->get(game => $id); }
sub get_join { my ($self, $id) = @_; return $self->get(join => $id); }
sub get_move { my ($self, $id) = @_; return $self->get(move => $id); }
sub get_user { my ($self, $id) = @_; return $self->get(user => $id); }
sub get {
   my ($self, $type, $id) = @_;
   my $hashref = $self->raw_get($type, $id);
   my $class = $hashref->{class} || 'Narsil::' . ucfirst($type);
   (my $package = $class . '.pm') =~ s{::}{/}gmxs;
   require $package;
   my $method = $class->can('create') || $class->can('new');
   return $class->$method(%$hashref, model => $self);
}

sub type_for {
   my ($self, $object) = @_;
   return 'game' if $object->isa('Narsil::Game');
   (my $type = lc(ref $object)) =~ s/.*:://mxs;
   return $type;
}
sub put {
   my ($self, $object) = @_;
   die 'unimplemented';
   # return $updated_object;
}
sub put_game { my ($self, $object) = @_; return $self->put($object); }
sub put_match { my ($self, $object) = @_; return $self->put($object); }
sub put_join { my ($self, $object) = @_; return $self->put($object); }
sub put_move { my ($self, $object) = @_; return $self->put($object); }
sub put_user { my ($self, $object) = @_; return $self->put($object); }

# FIXME requires more thinking...
sub match_join { my ($self, $user) = @_; die 'unimplemented' }

sub create_match {
   my ($self, %params) = @_;
   # receives user, gameid and configuration
   my $game = $self->get_game($params{gameid});
   return $game->create_match(%params);
}

sub locked_execute {
   my ($self, $match, $op) = @_;
   die 'unimplemented';
   # 1. start a transaction
   # 2. refresh match
   my $updated_match = $self->get_match($match->id());
   # 3. execute op
   my $retval = $op->($updated_match);
   # 4. release transaction
   return $retval;
}

1;
__END__

