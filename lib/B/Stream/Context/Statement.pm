
use v5.40;
use experimental qw[ class ];

class B::Stream::Context::Statement :isa(B::Stream::Context) {
    use overload '""' => \&to_string;
    field $op :param :reader;

    method addr { ${ $op } }

    method label   { $op->label   }
    method file    { $op->file    }
    method line    { $op->line    }
    method stash   { $op->stash   }
    method cop_seq { $op->cop_seq }

    method to_string {
        sprintf '%s [%d] %s:%d' => $self->stash->NAME, $self->cop_seq, $self->file, $self->line;
    }
}

class B::Stream::Context::InvisibleStatement :isa(B::Stream::Context) {
    use overload '""' => \&to_string;
    field $cv :param :reader;

    method addr { ${ $cv } }

    method label   { ''}
    method file    { $cv->FILE     }
    method line    { $cv->GV->LINE }
    method stash   { $cv->STASH    }
    method cop_seq { 0 }

    method to_string {
        sprintf '%s [%d] %s:%d' => $self->stash->NAME, $self->cop_seq, $self->file, $self->line;
    }
}
