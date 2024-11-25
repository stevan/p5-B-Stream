#!perl

use v5.40;
use experimental qw[ class ];

use lib 't/lib';

use Test::More;
use Data::Dumper;

use B::Stream::Tools::Debug;

use ok 'B::Stream';

package Foo::Bar {
    sub foobar {
        require Foo;
        Foo->VERSION(0.01);
        Foo->import(qw[ bar baz ]);
    }
}

class B::Stream::Parser {
    field $stream :param :reader;

    field $result :reader;
    field $error  :reader;

    field $buffer :reader;

    ADJUST {
        $stream = $stream->buffered;
        $buffer = $stream->source;

        $stream = $stream->peek(sub ($op) { say ">>>> Parsing: $op" });
    }

    method set_result ($r) { $result = $r }
    method set_error  ($e) { $error  = $e }

    method parse { ... }
}

class ModuleImport {
    use overload '""' => 'to_string';

    field $filename :param :reader;
    field $version  :param :reader = undef;
    field $imports  :param :reader = undef;

    method to_string {
        sprintf 'File: %s : %s (%s)' =>
            $filename,
            $version // '~',
            (join ', ' => @$imports)
    }
}

class B::Stream::Parser::ModuleImport :isa(B::Stream::Parser) {

    field $require;
    field $method_call;

    ADJUST {
        $require = B::Stream::Match::Builder->new
            ->starts_with( name => 'leavesub'  )
            ->followed_by( name => 'lineseq'   )
            ->followed_by( name => 'nextstate' )
            ->followed_by( name => 'require'   )
            ->matches_on( name  => 'const',
                on_match => sub ($op) { $op->op->sv->PV }
            )->build;

        $method_call = B::Stream::Match::Builder->new
            ->starts_with( name => 'lineseq', skippable => true )
            ->followed_by( name => 'nextstate' )
            ->followed_by( name => 'entersub' )
            ->matches_on( name => 'pushmark',
                on_match => sub ($) {
                    $self->stream
                         ->take_until(sub ($op) { $op->name eq 'method_named' })
                         ->collect( B::Stream::Tools::Collectors->ToList )
                }
            )->build;
    }

    method parse {
        my ($filename, $version, @imports);

        say "** starting buffering";
        $self->buffer->start_buffering;

        say "parsing ...";
        say "parsing filename ...";
        $filename = $self->stream->match($require);
        say "got ($filename) ...";



        say "parsing method calls ...";
        my @method_calls;
        while (my @method_call = $self->stream->match($method_call)) {
            if (scalar @method_call) {
                say "got method_call";
                push @method_calls => \@method_call;
            }
            else {
                say "failed to match!!";
                $self->set_error("Expected method call");
                return false;
            }
        }

        say "** stoping buffering";
        $self->buffer->stop_buffering;

        say "got ".(scalar @method_calls)." method calls";
        foreach my $method_call (@method_calls) {
            my $method_name = $method_call->[-1]->op->meth_sv->PV;
            say "checking method_call ($method_name) ...";
            if ($method_name eq 'import') {
                say "got \&import";
                if (scalar(@$method_call) > 2) {
                    @imports = map {
                        $_->op->sv->PV
                    } @{ $method_call }[1 .. ($#{$method_call} - 1) ];
                    say "got imports (".(join ', ' => @imports).")";
                }
            }
            elsif  ($method_name eq 'VERSION') {
                say "got \&VERSION";
                $version = $method_call->[-2]->op->sv->NV;
                say "got version ($version)";
            }
            else {
                say "got \&HUH??? $method_name ";
                $self->set_error("Unexpected method ($method_name)");
                return false;
            }
        }

        say "got result!";

        $self->set_result(ModuleImport->new(
            filename => $filename,
            version  => $version,
            imports  => \@imports
        ));

        say "got (".$self->result.")";

        return $self->result // $self->error;
    }
}

my $parser = B::Stream::Parser::ModuleImport->new(
    stream => B::Stream->new( from => \&Foo::Bar::foobar )
);

my $result = $parser->parse;
$parser->buffer->rewind;
say $parser->parse;
say $result;

#my $require = $stream->match($require_matcher);
#say "Got this from require: ".Dumper $require;
#
#my @method_args1 = $stream->match($method_arg_matcher);
#say "Got ".(scalar @method_args1)." method args back in the first set";
#print_ops(@method_args1);
#
#my @method_args2 = $stream->match($method_arg_matcher);
#say "Got ".(scalar @method_args2)." method args back in the second set";
#print_ops(@method_args2);

done_testing;
