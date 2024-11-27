#!perl

use v5.40;
use experimental qw[ class ];
use lib          qw[ t/lib ];

use Test::More;

use ok 'B::Stream';
use ok 'B::Stream::Parser';

use B::Stream::Tools::Debug;

package Foo::Bar {
    sub foobar {
        my $foo = 10;
        my $bar = 100;
        my $baz = ($foo + 5);
    }
}


my $parser = B::Stream::Parser->new(
    stream => B::Stream->new( from => \&Foo::Bar::foobar )
);

$parser->parse(B::Stream::Parser::Observer->new(
    on_next      => sub ($e) { say(('  ' x $e->op->depth), $e) },
    on_error     => sub ($e) { die $e },
    on_completed => sub { say 'done' },
));


done_testing;

__END__

