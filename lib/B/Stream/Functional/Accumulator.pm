
use v5.40;
use experimental qw[ class ];

class B::Stream::Functional::Accumulator :isa(B::Stream::Functional) {
    field $finisher :param = undef;
    field @acc;

    method apply ($arg) { push @acc => $arg; return; }

    method result { $finisher ? $finisher->( @acc ) : @acc }
}
