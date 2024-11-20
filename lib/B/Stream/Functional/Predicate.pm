
use v5.40;
use experimental qw[ class ];

class B::Stream::Functional::Predicate :isa(B::Stream::Functional) {
    field $f :param;

    method apply ($arg) { return !! $f->($arg) }
}
