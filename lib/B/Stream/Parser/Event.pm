
use v5.40;
use experimental qw[ class ];

class B::Stream::Parser::Event {
    use constant DEBUG => $ENV{DEBUG_EVENT} // 0;

    use overload '""' => 'to_string';
    field $op :param :reader;

    field $type :reader;
    ADJUST {
        $type = __CLASS__ =~ s/^B\:\:Stream\:\:Parser\:\:Event\:\://r;
    }

    method has_compliment { true }

    method is_enter   { !!(__CLASS__ =~ m/\:\:Enter/) }
    method is_leave   { !!(__CLASS__ =~ m/\:\:Leave/) }

    method compliment {
        return __CLASS__ =~ s/\:\:Enter/\:\:Leave/r if $self->is_enter;
        return __CLASS__ =~ s/\:\:Leave/\:\:Enter/r if $self->is_leave;
    }

    method create_compliment { $self->compliment->new( op => $op ) }

    method to_string {
        if (DEBUG) {
            state %colors;
            $colors{ $op->addr } //= [ map { int(rand(250)) } 1, 2, 3 ];
            sprintf "\e[48;2;%d;%d;%d;m%s( %s @ %d )\e[0m" =>
                $colors{ $op->addr }->@*,
                $type,
                $op->to_string,
                $op->depth;
        } else {
            sprintf "%s( %s @ %d )" =>
                $type,
                $op->to_string,
                $op->depth;
        }
    }
}

class B::Stream::Parser::Event::EnterSubroutine :isa(B::Stream::Parser::Event) {}
class B::Stream::Parser::Event::LeaveSubroutine :isa(B::Stream::Parser::Event) {}

class B::Stream::Parser::Event::EnterPreamble :isa(B::Stream::Parser::Event) {}
class B::Stream::Parser::Event::LeavePreamble :isa(B::Stream::Parser::Event) {}

class B::Stream::Parser::Event::EnterStatementSequence :isa(B::Stream::Parser::Event) {}
class B::Stream::Parser::Event::LeaveStatementSequence :isa(B::Stream::Parser::Event) {}

class B::Stream::Parser::Event::EnterStatement :isa(B::Stream::Parser::Event) {}
class B::Stream::Parser::Event::LeaveStatement :isa(B::Stream::Parser::Event) {}

class B::Stream::Parser::Event::EnterExpression :isa(B::Stream::Parser::Event) {}
class B::Stream::Parser::Event::LeaveExpression :isa(B::Stream::Parser::Event) {}

class B::Stream::Parser::Event::Terminal :isa(B::Stream::Parser::Event) {
    method has_compliment { false }
    method compliment { __CLASS__ }
}
