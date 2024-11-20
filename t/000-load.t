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
        my $x;
        foreach my $i ( 0 .. 10 ) {
            $x += $i + $foo * $bar;
        }
        return $x;
    }
}

my $color_fmt = "\e[48;2;%d;%d;%d;m";
my $reset     = "\e[0;m";

my sub gen_color { map { int(rand(255)) } qw[ r g b ] }

my @color = gen_color;

my @ops;
my $count = B::Stream
    ->new( from => \&Foo::Bar::foobar )
    ->when( B::Stream::Tools::Events->OnStatementChange, sub ($) { @color = gen_color })
    ->peek(sub ($op) {
        say((sprintf $color_fmt => @color),
            (sprintf '%-60s # %-40s ancestors: %s',
            ('..' x $op->depth).$op,
            ($op->statement // '~'),
            (join ' -> ' => map $_->name, $op->stack->@*)),
            $reset)
        ;
        #my $x = <>;
    })
    ->grep(sub ($op) { $op->name eq 'gv' })
    ->peek(sub ($op) { push @ops => $op })
    ->collect( B::Stream::Tools::Collectors->JoinWith(", ") );
    #->reduce(0, sub ($op, $acc) { $acc + 1 });

say "Count: ($count)";
say "Ops: ";
say join "\n" => map {
    ' -> '.(join ':', $_->name, $_->op->gv->NAME)
} @ops;

done_testing;
