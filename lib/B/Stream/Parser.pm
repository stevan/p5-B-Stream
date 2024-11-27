
use v5.40;
use experimental qw[ class ];

use B::Stream::Parser::Observer;
use B::Stream::Parser::Event;

class B::Stream::Parser {
    field $stream :param :reader;

    field $current_statement;
    field @stack;

    method parse ($observer) {
        my ($root, $error);
        try {
            $stream->foreach(sub ($op) {
                $root //= $op;
                $observer->on_next( $_ ) foreach $self->parse_op( $op );
            });
        } catch ($e) {
            $error = $e;
        }

        if ($error) {
            $observer->on_error($error);
            return false;
        }

        unless ($root) {
            $observer->on_error("No root found!");
            return false;
        }

        if ($current_statement) {
            #warn join ', ' => @stack;
            while (@stack) {
                last if $stack[-1]->addr == $current_statement->parent->addr;
                $observer->on_next(B::Stream::Parser::Event::LeaveExpression->new( op => pop @stack ));
            }
            $observer->on_next(B::Stream::Parser::Event::LeaveStatement->new( op => $current_statement ));
        }

        while (@stack) {
            $observer->on_next(B::Stream::Parser::Event::LeaveExpression->new( op => pop @stack ));
        }

        $observer->on_next(B::Stream::Parser::Event::LeaveSubroutine->new( op => $root ));
        $observer->on_completed;
        return true;
    }

    method parse_op ($op) {
        return B::Stream::Parser::Event::EnterSubroutine->new( op => $op )
            if $op->name eq 'leavesub';

        if ($op->name eq 'nextstate') {
            my @events;
            if (not defined $current_statement) {
                push @events => B::Stream::Parser::Event::EnterStatement->new( op => $op );
                $current_statement = $op;
            }
            elsif ($op->addr != $current_statement->addr) {
                #warn join ', ' => @stack;
                while (@stack) {
                    last if $stack[-1]->addr == $op->parent->addr;
                    push @events => B::Stream::Parser::Event::LeaveExpression->new( op => pop @stack );
                }

                push @events => (
                    B::Stream::Parser::Event::LeaveStatement->new( op => $current_statement ),
                    B::Stream::Parser::Event::EnterStatement->new( op => $op )
                );
                $current_statement = $op;
            }
            return @events;
        }


        my @events;
        #warn join ', ' => @stack;
        while (@stack) {
            last if $stack[-1]->addr == $op->parent->addr;
            push @events => B::Stream::Parser::Event::LeaveExpression->new( op => pop @stack );
        }

        if ($op->has_descendents) {
            push @stack => $op;
            push @events => B::Stream::Parser::Event::EnterExpression->new( op => $op );
        }
        else {
            push @events => B::Stream::Parser::Event::Terminal->new( op => $op );
        }

        return @events;
    }
}

