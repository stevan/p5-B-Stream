
use v5.40;
use experimental qw[ class ];

use B::Stream::Context::Optree;

class B::Stream::Source::Optree :isa(B::Stream::Source) {
    use constant DEBUG => $ENV{DEBUG} // 0;

    field $cv :param :reader;

    field $started = false;
    field $stopped = false;

    field $next;
    field @stack;

    ADJUST {
        $next = $cv->ROOT;
    }

    method depth { scalar @stack }

    method next {
        B::Stream::Context::Optree->new(
            source => $self,
            op     => $next
        )
    }

    method has_next {
        return false if not defined $next;

        say('-' x 40) if DEBUG;
        if (!$started) {
            $started = true;
            say "Not started yet, setting up $next" if DEBUG;
        }
        else {
            say "Processing $next" if DEBUG;

            if ($next->flags & B::OPf_KIDS) {
                say ".... $next has kids" if DEBUG;
                push @stack => $next;
                $next = $next->first;
                say ".... + $next is first kid" if DEBUG;
            }
            else {
                say ".... $next does not have kids" if DEBUG;
                my $sibling = $next->sibling;
                if ($$sibling) {
                    say ".... $next has sibling" if DEBUG;
                    $next = $sibling;
                    say ".... + $next is sibling" if DEBUG;
                }
                else {
                    say ".... $next does not have any more siblings" if DEBUG;
                    while (@stack) {
                        $next = pop @stack;
                        say "<< back to $next ..." if DEBUG;
                        my $sibling = $next->sibling;
                        if ($$sibling) {
                            $next = $sibling;
                            last;
                        }
                    }

                    unless (@stack) {
                        say "..... ** We ran out of stack, so we are back to root" if DEBUG;
                        $next = undef;
                        $stopped = true;
                    }
                }
            }
        }
        say "!!!! next is: ".($next // '~') if DEBUG;
        return false unless $next;
        return true;
    }
}
