
use v5.40;
use experimental qw[ class ];

use B    ();
use Carp ();

BEGIN { B::save_BEGINs(); }

use B::Stream::Functional;
use B::Stream::Functional::Accumulator;
use B::Stream::Functional::Consumer;
use B::Stream::Functional::Mapper;
use B::Stream::Functional::Predicate;
use B::Stream::Functional::Reducer;

use B::Stream::Operation;
use B::Stream::Operation::Reduce;
use B::Stream::Operation::Collect;
use B::Stream::Operation::ForEach;
use B::Stream::Operation::Map;
use B::Stream::Operation::Grep;
use B::Stream::Operation::Peek;
use B::Stream::Operation::When;

use B::Stream::Source;
use B::Stream::Source::Optree;

use B::Stream::Tools::Events;
use B::Stream::Tools::Collectors;

class B::Stream {
    field $from   :param         = undef;
    field $source :param :reader = undef;

    ADJUST {
        unless ($source) {
            die "You must pass in the 'from' parameter if you do not supply a source"
                unless $from;

            my $b;
            if (blessed $from && $from isa B::CV) {
                $b = $from;
            }
            elsif (reftype $from eq 'CODE') {
                $b = B::svref_2object($from);
            }
            else {
                die "Currently only CVs are supported (either a CODE ref or B::CV object), not $b"
            }

            $source = B::Stream::Source::Optree->new( cv => $b );
        }
    }

    my sub wrap_or_apply ($operation) {
        $operation isa B::Stream::Operation::Terminal
            ? $operation->apply
            : B::Stream->new( source => $operation )
    }

    ## ---------------------------------------------------------------------------------------------
    ## Terminals
    ## ---------------------------------------------------------------------------------------------

    method reduce ($init, $f) {
        wrap_or_apply B::Stream::Operation::Reduce->new(
            source  => $source,
            initial => $init,
            reducer => blessed $f ? $f : B::Stream::Functional::Reducer->new( f => $f )
        )
    }

    method foreach ($f) {
        wrap_or_apply B::Stream::Operation::ForEach->new(
            source   => $source,
            consumer => blessed $f ? $f : B::Stream::Functional::Consumer->new( f => $f )
        )
    }

    method collect ($acc) {
        wrap_or_apply B::Stream::Operation::Collect->new(
            source      => $source,
            accumulator => $acc
        )
    }

    ## ---------------------------------------------------------------------------------------------
    ## Operations
    ## ---------------------------------------------------------------------------------------------

    method when ($predicate, $f) {
        wrap_or_apply B::Stream::Operation::When->new(
            source    => $source,
            consumer  => blessed $f ? $f : B::Stream::Functional::Consumer->new( f => $f ),
            predicate => blessed $predicate
                            ? $predicate
                            : B::Stream::Functional::Predicate->new( f => $predicate )
        )
    }

    method map ($f) {
        wrap_or_apply B::Stream::Operation::Map->new(
            source => $source,
            mapper => blessed $f ? $f : B::Stream::Functional::Mapper->new( f => $f )
        )
    }

    method grep ($f) {
        wrap_or_apply B::Stream::Operation::Grep->new(
            source    => $source,
            predicate => blessed $f ? $f : B::Stream::Functional::Predicate->new( f => $f )
        )
    }

    method peek ($f) {
        wrap_or_apply B::Stream::Operation::Peek->new(
            source   => $source,
            consumer => blessed $f ? $f : B::Stream::Functional::Consumer->new( f => $f )
        )
    }
}
