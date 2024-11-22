#!perl

use v5.40;
use experimental qw[ class ];

use lib 't/lib';

use Test::More;
use Data::Dumper;

use ok 'B::Stream';

use B::Stream::Tools::Debug;

package Foo::Bar {
    use Foo 0.01;
    use Bar;

    sub foobar {
        my $foo = Foo::foo(bar());
        my $bar = bar();
        my $x;
        foreach my $i ( 0 .. 10 ) {
            $x += $i + $foo * $bar;
        }
        return $x;
    }
}

my $package = 'Foo::Bar';

subtest '... checking BEGIN blocks' => sub {

    my @BEGINS = B::begin_av->isa('B::SPECIAL') ? () : B::begin_av->ARRAY;
    ok(scalar(@BEGINS), '... we got some BEGIN blocks');

    my @mine;
    foreach my $BEGIN (@BEGINS) {
        next unless $BEGIN->STASH->NAME eq $package;
        push @mine => $BEGIN;
    }

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

    foreach my $b (@mine) {
        say sprintf '%s from %s' => $b->GV->NAME, $b->STASH->NAME;

        my $stream = B::Stream->new( from => $b );

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

        $stream->foreach(\&print_op);
    }
};


done_testing;
