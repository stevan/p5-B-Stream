
use v5.40;
use experimental qw[ class ];

class B::Stream::Parser::Event {
    use overload '""' => 'to_string';
    field $op :param :reader;

    field $type :reader;
    ADJUST {
        $type = __CLASS__ =~ s/^B\:\:Stream\:\:Parser\:\:Event\:\://r;
    }

    method to_string {
        sprintf '%s( %s )' => $type, $op->to_string;
    }
}

class B::Stream::Parser::Event::EnterSubroutine :isa(B::Stream::Parser::Event) {}
class B::Stream::Parser::Event::LeaveSubroutine :isa(B::Stream::Parser::Event) {}

class B::Stream::Parser::Event::EnterStatement  :isa(B::Stream::Parser::Event) {}
class B::Stream::Parser::Event::LeaveStatement  :isa(B::Stream::Parser::Event) {}

class B::Stream::Parser::Event::EnterExpression :isa(B::Stream::Parser::Event) {}
class B::Stream::Parser::Event::LeaveExpression :isa(B::Stream::Parser::Event) {}

class B::Stream::Parser::Event::Terminal        :isa(B::Stream::Parser::Event) {}
