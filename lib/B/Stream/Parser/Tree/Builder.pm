
use v5.40;
use experimental qw[ class ];

class B::Stream::Parser::Tree::Builder :isa(B::Stream::Parser::Observer) {
    field @stack        :reader;
    field $is_completed :reader = false;

    field $error;
    field $result;

    method build {
        die "Cannot call build if there has been an error"
            if $error;
        die "Cannot call build on an uncompleted tree"
            unless $is_completed;
        return $result;
    }

    method on_next ($e) {
        return if $error || $is_completed;

        if ($e isa B::Stream::Parser::Event::EnterSubroutine ||
            $e isa B::Stream::Parser::Event::EnterStatement  ||
            $e isa B::Stream::Parser::Event::EnterExpression ||
            $e isa B::Stream::Parser::Event::Terminal        ){
            push @stack => B::Stream::Parser::Tree->new( node => $e );
        }
        elsif ($e isa B::Stream::Parser::Event::LeaveExpression) {
            my @children = $self->collect_children( $e );
            $stack[-1]->add_children( reverse @children );
        }
        elsif ($e isa B::Stream::Parser::Event::LeaveStatement  ||
               $e isa B::Stream::Parser::Event::LeaveSubroutine ){
            my @children = $self->collect_children( $e );
            $stack[-1]->add_children( @children );
        }
    }

    method on_completed {
        $is_completed = true;
        $result = $stack[0];
    }

    method on_error ($e) {
        $is_completed = true;
        $error = $e
    }

    method collect_children ($e) {
        my @children;
        while (@stack) {
            last if $stack[-1]->node->op->addr == $e->op->addr;
            push @children => pop @stack;
        }
        return @children;
    }
}


