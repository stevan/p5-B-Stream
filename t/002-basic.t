#!perl

use v5.40;
use experimental qw[ class ];

use lib 't/lib';

use Test::More;
use Data::Dumper;

use B::Stream::Tools::Debug;

use ok 'B::Stream';

package Foo::Bar {
    sub foobar {
        require Foo;
        Foo->VERSION(0.01);
        Foo->import();
    }
}

my $stream = B::Stream->new( from => \&Foo::Bar::foobar );

my $require_matcher = B::Stream::Match::Builder->new
    ->starts_with( name => 'leavesub'  )
    ->followed_by( name => 'lineseq'   )
    ->followed_by( name => 'nextstate' )
    ->followed_by( name => 'require'   )
    ->matches_on( name  => 'const',
        on_match => sub ($op) {
            my $file    = $op->op->sv->PV;
            my $package = $file =~ s/\//\:\:/gr;
                $package =~ s/\.pm//;

            return +{ file => $file, package => $package };
        }
    )->build;

my $method_arg_matcher = B::Stream::Match::Builder->new
    ->starts_with( name => 'lineseq', skippable => true )
    ->followed_by( name => 'nextstate' )
    ->followed_by( name => 'entersub' )
    ->matches_on( name => 'pushmark',
        on_match => sub ($) {
            $stream->take_until(sub ($op) { $op->name eq 'method_named' })
                   ->collect( B::Stream::Tools::Collectors->ToList )
        }
    )->build;

my $require = $stream->match($require_matcher);
say "Got this from require: ".Dumper $require;

my @method_args1 = $stream->match($method_arg_matcher);
say "Got ".(scalar @method_args1)." method args back in the first set";
print_ops(@method_args1);

my @method_args2 = $stream->match($method_arg_matcher);
say "Got ".(scalar @method_args2)." method args back in the second set";
print_ops(@method_args2);

done_testing;
