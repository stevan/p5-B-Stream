#!perl

use v5.40;
use experimental qw[ class ];

use lib 't/lib';

use Test::More;

use ok 'B::Stream';

class Match {
    field $next :param = undef;

    method     next :lvalue { $next }
    method has_next { defined $next }

    method matches ($) { ... }
}

class Match::Predicate :isa(Match) {
    field $predicate :param :reader;

    method matches ($op) { $predicate->($op) }
}

class Match::ByName :isa(Match) {
    field $name :param :reader;

    method matches ($op) { $op->name eq $name }
}

class Match::Builder {
    field $build :reader;
    field $match;

    my sub build_match (%opts) {
        return Match::Predicate->new( %opts ) if $opts{predicate};
        return Match::ByName   ->new( %opts ) if $opts{name};
        die "Cannot build match, no 'name' or 'predicate' keys present";
    }

    method starts_with (%opts) {
        die "Cannot call 'starts_with' twice" if defined $build;
        $build = $match = build_match(%opts);
        $self;
    }

    method followed_by(%opts) {
        $match = $match->next = build_match(%opts);
        $self;
    }
}

class Op { field $name :param :reader }

my $matcher = Match::Builder->new
    ->starts_with( name => 'leavesub' )
    ->followed_by( predicate => sub ($op) { $op->name eq 'nextstate' } )
    ->followed_by( name => 'require' )
    ->followed_by( name => 'const' )
    ->build;

my @ops = (
    Op->new(name => 'leavesub'),
    Op->new(name => 'nextstate'),
    Op->new(name => 'require'),
    #Op->new(name => 'padsv'),
    Op->new(name => 'const'),
    Op->new(name => 'nextstate'),
);

my $result;
while (@ops) {
    my $op = shift @ops;
    if ($matcher->matches($op)) {
        if ($matcher->has_next) {
            $matcher = $matcher->next;
        }
        else {
            $result = $op;
            last;
        }
    }
    else {
        die "ERROR: got(".$op->name.") and expected something different";
    }
}

say $result->name;

done_testing;


__END__

class UsedModule {
    field $file    :param :reader;
    field $package :param :reader;
    field $version :param :reader = undef;
    field $imports :param :reader = undef;

    method has_version { defined $version }
    method has_imports { defined $imports }
}


class UsedModule::Builder {
    field %args;

    field $next;
    field $error;

    ADJUST {
        $next = \&start;
    }

    method accept ($op) { $next->($op) }

    method next :lvalue { $next }

    method error ($op, $expected) { $error = [ $op, $expected ] }

    method start ($op) {
        if ($op->name eq 'leavesub') {
            $self->next = \&find_require;
        }
        else {
            $self->error($op, 'leavesub');
        }
    }

    method find_require ($op) {
        if ($op->name eq 'leavesub') {
            $self->next = \&statement;
        }
        else {
            $self->error($op, 'leavesub');
        }
    }
}
