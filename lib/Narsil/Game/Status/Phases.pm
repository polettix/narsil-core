package Narsil::Game::Status::Phases;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;

use Moo::Role;

has phase => (
   is => 'rw',
   default => sub { 'setup' },
);

sub is_setup { return $_[0]->phase() eq 'setup' }
sub is_play  { return $_[0]->phase() eq 'play' }

sub to_setup { $_[0]->phase('setup'); return $_[0] }
sub to_play  { $_[0]->phase('play'); return $_[0] }


1;
__END__
