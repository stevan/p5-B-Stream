
use v5.40;
use experimental qw[ class ];

class B::Stream::Operation::Match :isa(B::Stream::Operation::Terminal) {
    field $matcher  :param :reader;
    field $source   :param :reader;

    method apply {
        my $current = $matcher;
        while ($source->has_next) {
            my $op = $source->next;

            if ($current->is_match($op)) {
                if ($current->has_next) {
                    $current = $current->next;
                }
                else {
                    return $current->match_found($op);
                }
            }
            else {
                last;
            }
        }
        return;
    }
}
