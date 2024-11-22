package B::Stream::Tools::Debug;

use v5.40;
use experimental qw[ builtin ];
use builtin      qw[ export_lexically ];

sub import {
    export_lexically(
        '&print_ops'    => \&print_ops,
        '&print_op'     => \&print_op,
        '&stringify_op' => \&stringify_op,
    );
}

sub print_ops (@ops) { print_op($_) foreach @ops }
sub print_op  ($op)  { say stringify_op($op)     }

sub stringify_op ($op) {
    sprintf '%15s:%04d │ %s%s' =>
            $op->statement->file,
            $op->statement->line,
            ('  ' x $op->depth),
            $op;
}

__END__
