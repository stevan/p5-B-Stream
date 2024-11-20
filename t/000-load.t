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

my $acc = B::Stream::Functional::Accumulator->new;

B::Stream->new( from => \&Foo::Bar::foobar )
    ->peek(sub ($op) {
        say(('..' x $op->depth), sprintf '%s[%s](%d)', $op->type, $op->name, $op->addr);
        my $x = <>;
    })
    ->collect($acc);

say join "\n" => map $_->name, $acc->result;

done_testing;
