
use v5.40;

use B::Stream::Functional::Accumulator;

package B::Stream::Tools::Collectors {

    sub ToList { B::Stream::Functional::Accumulator->new }

    sub JoinWith($, $sep='') {
        B::Stream::Functional::Accumulator->new(
            finisher => sub (@acc) { join $sep, @acc }
        )
    }

}
