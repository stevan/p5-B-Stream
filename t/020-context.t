#!perl

use v5.40;
use experimental qw[ class ];

use lib 't/lib';

use Test::More;

use ok 'B::Stream';

## -----------------------------------------------------------------------------
## populate this ...
## -----------------------------------------------------------------------------

# We need to extract all this information using B
# and store it here for processing.

class DecompilationUnit {
    field $filename     :param :reader;

    field $begin_blocks :param :reader;
    field $symbol_table :param :reader;
    field $main_root    :param :reader; # collect any statements for this filename
}

## -----------------------------------------------------------------------------
## then use it to generate this ...
## -----------------------------------------------------------------------------

# The module object is the root of the tree.
#
# NOTE:
# The root namespace of a module will directly
# map to the filename even if there is no
# explicit code that creates that package.
#
# NOTE:
# Ideally all the sub-packages fall inside the
# root namespace ($namespaces->[0]) but in the
# case where someone defines a package that is
# outside of the root, then multiple namespace
# objects will be added.
#
# NOTE:
# pragmas loaded before any package definition
# will show up as being in the main:: package
# but in the .pm file. These should be noted
# differently than the ones inside a package
# and can be thought of as the top level
# compilation environment.

class Module {
    field $filename   :param :reader;
    field $pragmas    :param :reader;

    field @namespaces :reader;

    method add_namespace ($ns) { push @namespaces => $ns }
}

## -----------------------------------------------------------------------------

class Abstract::TracksUsage {
    field @usage :reader;
    method add_usage ($usage) { push @usage => $usage }
}

class Usage {}
class Usage::Define :isa(Usage) {}
class Usage::Read   :isa(Usage) {}
class Usage::Write  :isa(Usage) {}
class Usage::Call   :isa(Usage) {}

## -----------------------------------------------------------------------------

# Many pragmas are lexically scoped, which means that
# a `use v5.40` at the top of a .pm file will have a
# lexical effect on all subsequent package definitions
# in that file.

class Pragmas {
    field @active_pragmas :reader;

    method add_active_pragma($pragma) { push @active_pragmas => $pragma }
}

# NOTE:
# since pragmas are lexical we want to try
# and map this to the actual callsite so
# that we can track their usage in the
# program flow. This might end up being
# quite tricky since these will show up
# in the BEGIN blocks and also show up
# as hints in the COP operations.

class ActivePragma :isa(Abstract::TracksUsage) {
    field $name  :param :reader;
    field $flags :param :reader;
}

## -----------------------------------------------------------------------------

# The namespace is a root container that captures the
# entire namespace defined witin the .pm file. As mentioned
# above, it is possible that this package is not explicitly
# defined, but that is okay. It is also okay if there are
# many sub-packages defined in the same .pm file.
#
# We also need to make a note of pragmas used in the root
# package, as they can affect the environment of the
# subsequent packages as well.

class Namespace {
    field $name    :param :reader;
    field $pragmas :param :reader;

    field @packages :reader;
}

## -----------------------------------------------------------------------------
## Packages
## -----------------------------------------------------------------------------

# Now we are at a package level and things are more clear.
# So we can start gathering more detailed information.

# NOTE:
# not all BEGIN blocks will have been imports, so we stash
# those for analysis later

class Package {
    field $name    :param :reader;
    field $pragmas :param :reader;

    field @begin_blocks   :reader;
    field @symbols        :reader;
    field @module_imports :reader;

    method add_begin_block   ($block)  { push @begin_blocks   => $block  }
    method add_symbol        ($symbol) { push @symbols        => $symbol }
    method add_module_import ($import) { push @module_imports => $import }
}

## -----------------------------------------------------------------------------
## Symbols are the mapping of name to value inside a package
## -----------------------------------------------------------------------------

class Symbol :isa(Abstract::TracksUsage) {
    field $name    :param :reader;
    field $package :param :reader;
    field $value   :param :reader = undef;

    field $type :reader;
    ADJUST {
        $type = (split '::' => __CLASS__)[-1];
    }

    method sigil { ... }

    method has_value { defined $value }
    method set_value ($v) { $value = $v }
}

class Symbol::Scalar :isa(Symbol) {
    use constant sigil => '$';
}

class Symbol::Array :isa(Symbol) {
    use constant sigil => '@';
}

class Symbol::Hash :isa(Symbol) {
    use constant sigil => '%';
}

class Symbol::Code :isa(Symbol) {
    use constant sigil => '&';
}

class Symbol::Glob :isa(Symbol) {
    use constant sigil => '*';

    method is_stash { !! ($self->name =~ /\:\:$/) }
}

## -----------------------------------------------------------------------------
## Values that symbols point to ...
## -----------------------------------------------------------------------------

class Value {}
class Value::Scalar :isa(Value) {}
class Value::Array  :isa(Value) {}
class Value::Hash   :isa(Value) {}
class Value::Code   :isa(Value) {}
class Value::Glob   :isa(Value) {}

## -----------------------------------------------------------------------------
## Module imports are basically `use` statements
## We collect the required version and import args from the import site,
## but later we will connect the imported symbols to this import
## statement when we see then in the package stashes.
## -----------------------------------------------------------------------------

# NOTE:
# in the long run, we probably want to treat `use constant` differently
# than just a normal import, as it's main goal is to create the fresh
# new constant in your namespace, rather than import something that is
# defined elsewhere. For now we will leave this as is to preserve
# consistency, but later anaylsis stages should take this into account.

class ModuleImport {
    field $filename         :param :reader;
    field $version          :param = undef;
    field $import_args      :param = undef;
    field $exported_symbols :param = undef;

    field $package :reader;

    ADJUST {
        $package = $filename =~ s/\.pm$//r;
        $package =~ s/\//\:\:/g;
    }

    method has_version          { defined $version          }
    method has_import_args      { defined $import_args      }
    method has_exported_symbols { defined $exported_symbols }

    # TODO:
    # these both probably need some post
    # processing, to make them into something
    # that is consistent and useful.
    # For version
    #   - we can use version objects to normalize?
    # For imports
    #   - we can seperate the constants from objects
    #     and wrap them all so we can introspect them
    #     easily and perhaps compare them to some kind
    #     of module interface
    method version { $version  }
    method imports { @$import_args }

    method exported_symbols { @$exported_symbols }
}

# simple export, either SCALAR, ARRAY or HASH
class ExportedSymbol :isa(Abstract::TracksUsage) {
    field $symbol :param :reader;
    field $origin :param :reader;
}

# an exported constant is just an exported subroutine
# which is itself is constant-folded. Same as with the
# regular subroutines, we want to track usages which
# we can do by matching the CVs constant to the `sv`
# stored in a `const` operation
class ExportedConstant :isa(ExportedSubroutine) {
    field $constant_value :param :reader;
}

## -----------------------------------------------------------------------------


done_testing;

__END__





















