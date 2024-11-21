#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use ok 'B::Stream';

package Foo::Bar {
    use Foo;
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

    foreach my $b (@mine) {
        say sprintf '%s from %s' => $b->GV->NAME, $b->STASH->NAME;
        B::Stream->new( from => $b )->foreach(sub ($op) {
            say sprintf '%15s:%04d │ %s%s' => $op->statement->file, $op->statement->line, ('  ' x $op->depth), $op;
        })
    }
};

done_testing;
