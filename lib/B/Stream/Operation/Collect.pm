
use v5.40;
use experimental qw[ class ];

class B::Stream::Operation::Collect :isa(B::Stream::Operation::Terminal) {
    field $source      :param;
    field $accumulator :param;

    method apply {
        while ($source->has_next) {
            $accumulator->apply($source->next);
        }
        return $accumulator->result;
    }
}
