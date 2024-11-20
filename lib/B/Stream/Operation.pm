
use v5.40;
use experimental qw[ class ];

class B::Stream::Operation {}

class B::Stream::Operation::Node :isa(B::Stream::Operation) {
    method     next { ... }
    method has_next { ... }
}

class B::Stream::Operation::Terminal :isa(B::Stream::Operation) {
    method apply { ... }
}
