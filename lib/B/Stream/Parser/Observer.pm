
use v5.40;
use experimental qw[ class ];

class B::Stream::Parser::Observer {
    field $on_next      :param;
    field $on_error     :param;
    field $on_completed :param;

    method on_next  ($e) { $on_next      ? $on_next->($e)    : () }
    method on_error ($e) { $on_error     ? $on_error->($e)   : () }
    method on_completed  { $on_completed ? $on_completed->() : () }
}
