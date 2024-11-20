
use v5.40;
use experimental qw[ class ];

class B::Stream::Functional::Reducer :isa(B::Stream::Functional) {
    field $f :param;

    method apply ($arg, $acc) { $f->($arg, $acc) }
}
