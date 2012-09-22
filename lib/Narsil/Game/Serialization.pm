package Narsil::Game::Status;

use strict;
use warnings;
use Carp;
use English qw< -no_match_vars >;
use Scalar::Util qw< blessed >;
use Moo;
use JSON;
use Storable qw< dclone >;

sub _thaw {
   my ($definition) = @_;
   $definition = decode_json($definition) unless ref $definition;
   my ($class, $args) = @{$definition}{qw< class args >};
   (my $package = $class . '.pm') =~ s{(?: :: | ')}{/}gmxs;
   require $package;
   return $class->new(%$args);
}

sub rise {
   my $type = ref $_[0] or return;
   if ($type eq 'ARRAY') {
      respring($_) for @$type;
      return;
   }
   elsif ($type eq 'HASH') {
      my $args = $_[0]->{args};
      respring($_) for values %$args;

      if (defined (my $class = $_[0]->{class})) { # object
         (my $package = $class . '.pm') =~ s{(?: :: | ')}{/}gmxs;
         require $package;
         $_[0] = $class->new(%$args);
         return;
      }
      else { # plain hash
         $_[0] = $args;
         return;
      }
   }
   else {
      die { reason => "invalid ref $type" };
   }
   return;
}



sub thaw {
   my ($definition) = @_;
   $definition = decode_json($definition) unless ref $definition;
   my $clone = dclone($definition); # detach from original
   rise($clone);
   return $clone;
}

sub fall {
   my ($object) = @_;
   my $type = ref $object or return $object;
   my $undertype = $type;
   my ($undertype) = blessed($object) ? ("$object" =~ m{=([A-Z]+)\(}mxs) : ($type);
   my $retval;
   if ($type eq 'ARRAY') {
      return [ map { fall($_) } @$object ];
   }
   elsif ($type eq 'HASH') {
      return { args => { map { $_ => fall($object->{$_}) } keys %$object } };
   }
   elsif (blessed $object) {
      my $retval = { class => $type };
      if ($object->can('as_hash')) {
         $retval->{args} = $object->as_hash()
      }
      else {
         my ($undertype) = "$object" =~ m{=([A-Z]+)\(}mxs;
         die { reason => "object of type $type does not support as_hash() and is not a HASH" }
            unless $undertype eq 'HASH';
         $retval->{args} = { map { $_ => fall($object->{$_}) } keys %$object };
      }
      return $retval;
   }
   else {
      die { reason => "invalid type $type ($subtype)" };
   }
   return;
}

sub freeze {
   my ($object) = @_;
   my $plain = fall($object);

}


has field => (
   is => 'rw',
   isa => sub { die {} unless $_[0]->isa('Narsil::Game::Field') },
   coerce => sub {
      my ($input) = @_;
      return $input if $input->isa('Narsil::Game::Field');
      return _thaw($input);
   },
   lazy => 1,
   predicate => 'has_field',
   clearer => 'clear_field',
   builder => 'BUILD_field',
);
sub BUILD_field { die { reason => 'no field at all!' } }




1;
__END__

