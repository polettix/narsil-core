package Narsil::Game::Status;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use Scalar::Util qw< blessed >;
use Moo;
use JSON;
use Digest::MD5 qw< md5_hex >;
use Narsil::Game::Field;

has summary => (
   is => 'rw',
   lazy => 1,
   predicate => 'has_summary',
   clearer   => 'clear_summary',
   builder   => 'BUILD_summary',
);
sub BUILD_summary {
   my $plain = $_[0]->plain();
   return $plain->{summary};
}
sub update_summary {
   my ($self) = @_
   $self->summary($self->BUILD_summary());
}
sub calculate_summary {
   my ($hash) = @_;
   delete $hash->{summary};
   return md5_hex(encode_json($hash));
}
sub plain {
   my ($self) = @_;
   my %retval;
   while (my ($k, $v) = each %$self) {
      $retval{$k} = blessed($v) ? $v->plain() : $v;
   }
   my $summary = calculate_summary(\%retval);
   $retval{summary} = $summary;
   return \%retval;
}

has field => (
   is => 'rw',
   isa => sub { die { reason => 'not a Narsil::Game::Field' } unless $_[0]->isa('Narsil::Game::Field') },
   coerce => \&coerce_field,
   lazy => 1,
   predicate => 'has_field',
   clearer => 'clear_field',
   builder => 'BUILD_field',
);
sub BUILD_field {
   my ($self) = @_;
   die { reason => 'no field at all!' }
      unless $self->has_raw();
   my $hash = decode_json($self->raw());
   return coerce_field($hash->{field});
}
sub coerce_field {
   my ($input) = @_;
   return $input if blessed $input;
   return Narsil::Game::Field->from_hash($input);
}

has players => (
   is => 'rw',
   lazy => 1,
   predicate => 'has_players',
   clearer => 'clear_players',
   builder => 'BUILD_players',
);
sub BUILD_players {
   my ($self) = @_;
   die { reason => 'no players at all!' }
      unless $self->has_raw();
   my $hash = decode_json($self->raw());
   return $hash->{players} // [];
}

has current_player_id => (
   is => 'rw',
   default => sub { 0 },
);

sub current_player {
   my ($self) = @_;
   my $i = $self->current_player_id();
   my $ps = $self->players();
   return $ps->[$i % @$ps];
}

sub pass_player {
   my ($self) = @_;
   my $i = $self->current_player_id();
   my $ps = $self->players();
   $self->current_player_id(($i + 1) % @$ps);
   return $self->current_player();
}

sub is_current_player {
   my ($self, $userid) = @_;
   return $self->current_player() eq $userid;
}

sub thaw {
   my ($self, $raw) = @_;
   my $hash = decode_json($raw);
   my $new = $self->new(%$hash, raw => $raw);
   return $new unless ref $self;
   %$self = %$new;
   return $self;
}

sub _freeze {
   my ($self) = @_;
   return encode_json($self->to_hash());
}
sub freeze {
   my ($self) = @_;
   my $raw = $self->_freeze();
   $self->raw($raw);
   return $raw;
}

sub equivalent_to { # assumes raw definitions are valid
   my ($self, $other) = @_;
   return $self->raw() eq $other->raw();
}

sub to_hash {
   my ($self) = @_;
   my %hash = %$self;
   $hash{field} = $self->field()->to_hash();
   delete $hash{raw};
   return \%hash;
}

1;
__END__

