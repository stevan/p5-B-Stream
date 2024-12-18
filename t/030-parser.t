#!perl

use v5.40;
use experimental qw[ class ];
use lib          qw[ t/lib ];

use Test::More;
use Data::Dumper;

use ok 'B::Stream';
use ok 'B::Stream::Parser';

use B::Stream::Tools::Debug;

package Foo::Bar {
    sub foobar ($x) {
        my $foo = 10;
        {
            my $bar = 100;
            foreach my $x ( 1 .. 100 ) {
                my $baz = ($foo + 5);
            }
        }
    }
}

B::Stream->new( from => \&Foo::Bar::foobar )->foreach(\&print_op);

my $stream = B::Stream->new( from => \&Foo::Bar::foobar );
my $parser = B::Stream::Parser->new( stream => $stream );
my $result = $parser->parse;

die $result // '!!!!' unless defined $result && blessed $result;

$result->traverse(sub ($n, $depth) {
    say(('  ' x $depth), $n->node->to_string);
});

done_testing;

__END__

