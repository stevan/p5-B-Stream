#!perl

use v5.40;
use experimental qw[ class ];
use lib          qw[ t/lib ];

use Test::More;

use ok 'B::Stream';
use ok 'B::Stream::Parser';

use B::Stream::Tools::Debug;

package Foo::Bar {
    sub foobar {
        my $foo = 10;
        my $bar = 100;
        my $baz = ($foo + 5);
    }
}

class Tree {
    field $node :param :reader = undef;
    field @children    :reader;

    method is_root { defined $node }

    method add_children (@c) { push @children => @c }

    method traverse ($f) {
        $f->($self) if $node;
        foreach my $child (@children) {
            $child->traverse($f);
        }
    }

    method to_JSON {
        return +{
            node     => $node->to_string,
            children => [ map $_->to_JSON, @children ],
        }
    }
}

my $parser = B::Stream::Parser->new(
    stream => B::Stream->new( from => \&Foo::Bar::foobar )
);

my @stack;
$parser->parse(B::Stream::Parser::Observer->new(
    on_next => sub ($e) {
        say(('  ' x $e->op->depth), $e->op->to_string);

        if ($e isa B::Stream::Parser::Event::StartSubroutine) {
            push @stack => Tree->new( node => $e );
        }
        elsif ($e isa B::Stream::Parser::Event::StartStatement) {
            push @stack => Tree->new( node => $e );
        }
        elsif ($e isa B::Stream::Parser::Event::StartExpression) {
            push @stack => Tree->new( node => $e );
        }
        elsif ($e isa B::Stream::Parser::Event::Terminal) {
            push @stack => Tree->new( node => $e );
        }
        elsif ($e isa B::Stream::Parser::Event::EndExpression) {
            my @children;
            my $start;
            while (@stack) {
                my $next = $stack[-1];
                if ($next isa B::Stream::Parser::Event::StartExpression
                    && $next->op->addr == $e->op->addr) {
                    $start = $next;
                    last;
                }
                else {
                    push @children => pop @stack;
                }
            }
            $start->add_children( @children );
        }
        elsif ($e isa B::Stream::Parser::Event::EndStatement) {
            my @children;
            my $start;
            while (@stack) {
                my $next = $stack[-1];
                if ($next isa B::Stream::Parser::Event::StartStatement
                    && $next->op->addr == $e->op->addr) {
                    $start = $next;
                    last;
                }
                else {
                    push @children => pop @stack;
                }
            }
            $start->add_children( @children );
        }
        elsif ($e isa B::Stream::Parser::Event::EndSubroutine) {
            my @children;
            my $start;
            while (@stack) {
                my $next = $stack[-1];
                if ($next isa B::Stream::Parser::Event::StartSubroutine
                    && $next->op->addr == $e->op->addr) {
                    $start = $next;
                    last;
                }
                else {
                    push @children => pop @stack;
                }
            }
            $start->add_children( @children );
        }
    },
    on_completed => sub {
        say 'done'
    },
    on_error => sub ($e) {
        die $e
    }
));


use Data::Dumper;
warn Dumper \@stack;

my ($root) = @stack;

warn Dumper $root->to_JSON;



done_testing;

__END__

