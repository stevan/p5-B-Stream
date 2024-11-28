
use v5.40;
use experimental qw[ class ];

class B::Stream::Parser::Tree {
    field $node :param :reader = undef;
    field @children    :reader;

    method is_root { defined $node }

    method add_children (@c) { push @children => @c }

    method to_JSON {
        return +{
            node     => $node->to_string,
            children => [ map $_->to_JSON, @children ],
        }
    }
}
