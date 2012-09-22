package Narsil::Game::Status;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use Scalar::Util qw< blessed >;
use Digest::MD5 qw< md5_hex >;
use JSON;
use Moo;

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
   my ($self) = @_;
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
      $v = blessed($v) ? $v->plain() : $v;
      next unless defined $v;
      $retval{$k} = $v;
   }
   my $summary = calculate_summary(\%retval);
   $retval{summary} = $summary;
   return \%retval;
}
sub equivalent_to { # assumes raw definitions are valid
   my ($self, $other) = @_;
   my $other_summary = blessed $other ? $other->summary() : $other->{summary};
   return $self->summary() eq $other_summary;
}

1;
__END__

