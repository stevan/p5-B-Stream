
use v5.40;
use experimental qw[ class ];

class B::Stream::Functional::Consumer :isa(B::Stream::Functional) {
    field $f :param;

    method apply (@args) { $f->(@args); return; }
}
