
use v5.40;
use experimental qw[ class ];

use B    ();
use Carp ();

use B::Stream::Functional;
use B::Stream::Functional::Accumulator;
use B::Stream::Functional::Consumer;
use B::Stream::Functional::Mapper;
use B::Stream::Functional::Predicate;

use B::Stream::Operation;
use B::Stream::Operation::Collect;
use B::Stream::Operation::ForEach;
use B::Stream::Operation::Map;
use B::Stream::Operation::Peek;

use B::Stream::Source;
use B::Stream::Source::Optree;

class B::Stream {
    field $from :param;

    field $source :reader;

    ADJUST {
        my $b = B::svref_2object($from);

        die "Currently only CV streams are supported, not $b"
            unless $b isa B::CV;

        $source = B::Stream::Source::Optree->new( cv => $b );
    }

    method foreach ($f) {
        B::Stream::Operation::ForEach->new(
            source   => $source,
            consumer => B::Stream::Functional::Consumer->new( f => $f )
        )->apply
    }
}
