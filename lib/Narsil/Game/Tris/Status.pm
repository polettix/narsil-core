package Narsil::Game::Tris::Status;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;

use Moo;
extends 'Narsil::Game::Status';
with 'Narsil::Game::Status::ForRectangularField';
with 'Narsil::Game::Status::Field';
with 'Narsil::Game::Status::RoundRobin';


1;
__END__

