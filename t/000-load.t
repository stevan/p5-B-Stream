#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use ok 'B::Stream';

package Foo::Bar {
    use Foo;
    use Bar;

    sub foobar {
        my $foo = Foo::foo(Foo::bar());
        my $bar = Foo::bar();
        my $x;
        foreach my $i ( 0 .. 10 ) {
            $x += $i + $foo * $bar;
        }
        return $x;
    }
}

my $color_fmt = "\e[48;2;%d;%d;%d;m";
my $invert    = "\e[7m";
my $reset     = "\e[0m";

my sub gen_color { map { int(rand(50)) * 5 } qw[ r g b ] }

my $color = [gen_color];

my @colors = ($color);

my @ops;
my $count = B::Stream
    ->new( from => \&Foo::Bar::foobar )
    ->when( B::Stream::Tools::Events->OnStatementChange, sub ($) { push @colors => [gen_color] })
    ->when( B::Stream::Tools::Events->InsideCallSite, sub ($op) {
        if ($op->name eq 'entersub') {
            push @colors => [gen_color];
        }
    })
    ->peek(sub ($op) {
        say((sprintf $color_fmt => $colors[-1]->@*),
            (sprintf '%-60s # %-40s ancestors: %s',
            ('..' x $op->depth).$op,
            ($op->statement // '~'),
            (join ' -> ' => map $_->name, $op->stack->@*)),
            $reset)
        ;
        if ($op->name eq 'gv') {
            pop @colors;
        }
        #my $x = <>;
    })
    ->grep(sub ($op) { $op->name eq 'gv' })
    ->peek(sub ($op) { push @ops => $op })
    ->map(sub ($op) {
        my $gv = $op->op->gv;
        join '::' => $gv->STASH->NAME, $gv->NAME
    })
    ->collect( B::Stream::Tools::Collectors->JoinWith(", ") );
    #->reduce(0, sub ($op, $acc) { $acc + 1 });

say "Callsites: ($count)";
say "Ops: ";
say join "\n" => map {
    ' -> '.(join ':', $_->name, $_->op->gv->NAME)
} @ops;

done_testing;
