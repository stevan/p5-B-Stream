
use v5.40;
use experimental qw[ class ];

class B::Stream::Operation::ForEach :isa(B::Stream::Operation::Terminal) {
    field $source   :param;
    field $consumer :param;

    method apply {
        while ($source->has_next) {
            $consumer->apply($source->next);
        }
        return;
    }
}
