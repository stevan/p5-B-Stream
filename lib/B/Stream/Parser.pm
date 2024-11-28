
use v5.40;
use experimental qw[ class ];

use B::Stream::Parser::Observer;
use B::Stream::Parser::Event;

use B::Stream::Parser::Tree;
use B::Stream::Parser::Tree::Builder;

class B::Stream::Parser {
    field $stream :param :reader;

    field $tree_builder;
    field $current_statement;
    field @stack;

    ADJUST {
        $tree_builder = B::Stream::Parser::Tree::Builder->new;
    }

    method parse {

        my ($root, $error);
        try {
            $stream->foreach(sub ($op) {
                $root //= $op;
                $tree_builder->on_next( $_ ) foreach $self->parse_op( $op );
            });
        } catch ($e) {
            $error = $e;
        }

        if ($error) {
            $tree_builder->on_error($error);
            return $tree_builder->error;
        }

        unless ($root) {
            $tree_builder->on_error("No root found!");
            return $tree_builder->error;
        }

        if ($current_statement) {
            #warn join ', ' => @stack;
            while (@stack) {
                last if $stack[-1]->addr == $current_statement->parent->addr;
                $tree_builder->on_next(B::Stream::Parser::Event::LeaveExpression->new( op => pop @stack ));
            }
            $tree_builder->on_next(B::Stream::Parser::Event::LeaveStatement->new( op => $current_statement ));
        }

        while (@stack) {
            $tree_builder->on_next(B::Stream::Parser::Event::LeaveExpression->new( op => pop @stack ));
        }

        $tree_builder->on_next(B::Stream::Parser::Event::LeaveSubroutine->new( op => $root ));
        $tree_builder->on_completed;

        return $tree_builder->build;
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

