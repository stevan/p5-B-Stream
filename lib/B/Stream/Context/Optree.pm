
use v5.40;
use experimental qw[ class ];

class B::Stream::Context::Optree :isa(B::Stream::Context) {
    field $source :param;
    field $op     :param :reader;

    field $name    :reader;
    field $is_null :reader = false;

    ADJUST {
        $is_null = $op->name eq 'null';
        $name    = $is_null ? substr(B::ppname( $op->targ ), 3) : $op->name;
    }

    ## ---------------------------------------------------------------------------------------------
    ## op stuff
    ## ---------------------------------------------------------------------------------------------

    method type { B::class($op) }
    method addr { ${ $op }  }

    method flags   { $op->flags   }
    method private { $op->private }
    method target  { $op->targ    }

    method has_pad_target { $op->targ > 0 }

    method wants_void         { ($op->flags & B::OPf_WANT) == B::OPf_WANT_VOID   }
    method wants_scalar       { ($op->flags & B::OPf_WANT) == B::OPf_WANT_SCALAR }
    method wants_list         { ($op->flags & B::OPf_WANT) == B::OPf_WANT_LIST   }

    method has_descendents    { $op->flags & B::OPf_KIDS    }
    method was_parenthesized  { $op->flags & B::OPf_PARENS  }
    method return_container   { $op->flags & B::OPf_REF     }
    method is_lvalue          { $op->flags & B::OPf_MOD     }
    method is_mutator_varient { $op->flags & B::OPf_STACKED }
    method is_special         { $op->flags & B::OPf_SPECIAL }

    ## ---------------------------------------------------------------------------------------------
    ## Context stuff
    ## ---------------------------------------------------------------------------------------------

    method depth { $source->depth }
}
