
use v5.40;
use experimental qw[ class ];

class B::Stream::Operation::Reduce :isa(B::Stream::Operation::Terminal) {
    field $source  :param;
    field $initial :param;
    field $reducer :param;

    method apply {
        my $acc = $initial;
        while ($source->has_next) {
            $acc = $reducer->apply($source->next, $acc);
        }
        return $acc;
    }
}

