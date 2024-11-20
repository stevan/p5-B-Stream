#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use ok 'B::Stream';

package Foo::Bar {
    use Foo;
    use Bar;

    sub foobar {
        my $foo = Foo::foo();
        my $bar = Foo::bar();
    }
}

my @ops;
my $count = B::Stream
    ->new( from => \&Foo::Bar::foobar )
    ->peek(sub ($op) {
        say sprintf '%-40s # %-40s ancestors: %s',
            ('..' x $op->depth).$op,
            ($op->statement // '~'),
            (join ' -> ' => map $_->name, $op->stack->@*);
        #my $x = <>;
    })
    ->grep(sub ($op) { $op->name eq 'gv' })
    ->peek(sub ($op) { push @ops => $op })
    ->reduce(0, sub ($op, $acc) { $acc + 1 });

say "Count: $count";
say "Ops: ";
say join "\n" => map {
    ' -> '.(join ':', $_->name, $_->op->gv->NAME)
} @ops;

done_testing;
