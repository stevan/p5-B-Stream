<!----------------------------------------------------------------------------->
# NOTES
<!----------------------------------------------------------------------------->

## Decompiler Input

We can only decompile a single `.pm` file at a time, which implies a namespace
(via the filename) but could contain other namespaces as well.

In the `CHECK` phase we can collect the following information using `B`.

- [ ] all relevant BEGIN statements (as CVs)
- [ ] all locally defined subroutines (CVs)
- [ ] the relevant statemtents in B::main_root

## Decompiler Output

At this point we should have sufficient information to be able to infer the
following bits of information.

- [ ] set of "module imports" and any arguments to them
    - [ ] handles all distinct (modules+imports) just as `perl` would
- [ ] set of all "imported subroutines"
    - [ ] information about any usage (which sub/statement/op call it)
- [ ] set of all "imported constants"
    - [ ] information about the `SV` of the constant value
    - [ ] information about any usage (which sub/statement/op call it)
- [ ] set of all "locally defined variables ""
    - [ ] `our` variables stored in the STASH
    - [ ] `my` variables within the package definition scope
    - [ ] information about any usage (which sub/statement/op use it)
- [ ] set of all "locally defined subroutines"
    - [ ] CVs stored in the STASH
    - [ ] anon or lexical CVs stored in "locally defined variables"
    - [ ] anon or lexical CVs stored in the PADs of other CVs
    - [ ] information about any usage (which sub/statement/op call it)
- [ ] set of classes and methods used
    - [ ] connect classes to "module imports" when possible
    - [ ] connect methods to classes when possible
    - [ ] information about any usage (which sub/statement/op call it)

## Decompiler Phases

We could get all the above information out of the input by following the
steps listed here.

- [ ] module imports
    - [ ] find module name, version and import args by processing the `BEGIN` CVs
        - [ ] if `perl` generated code from `use` we can process it
            - NOTE: remember the same module can be imported twice with
                    different import arguments.
            - [ ] make special note of things like `constant`
                - [ ] find the name of the constant itself for later
                - NOTE: treat this as if it was locally defined instead of
                        an import that is owned by `constant`
        - [ ] otherwise, put it in the CV queue to be processed

- [ ] walk the namespace
    - [ ] collect all the symbols that contain values
    - [ ] if it is a CV, put it in the queue to be processed

- [ ] infer package type
    - [ ] it is definintely a class if ...
        - it uses the `class` feature
        - has anything inside `@ISA`
        - either `base` or `parent` are found in the "module imports"
    - [ ] it might be a class if ...
        - it has a `new` subroutine
        - most all of the subroutines have a `$self` lexical
            - often coming from sub arguments
    - [ ] otherwise treat it as a regular package

- [ ] check the statements in B::main_root for anything relevant, such as ...
    - [ ] anon or my subroutines being created
        - [ ] put these in the CV queue to be processed
    - [ ] any package lexicals being created
    - [ ] any values added to `our` variables

- [ ] pre-process the CV queue
    - [ ] find all imported subroutines
        - [ ] the `STASH` method of `CV` should give the comp-stash
            - [ ] if it is not equal to the namespace then
                - [ ] it is am imported subroutine
        - [ ] remove this from the queue and ...
            - [ ] store it with the importing module data
    - [ ] find all imported constants
        - XXX: most constants are imported using the `constant` module, so
               this should cover 90% of them. The others will be locally defined
               and might need some work to figure out.
        - [ ] they should show up as constant folded CVs in the stash
            - [ ] we can access the folded `sv` via `XSUBANY`
        - [ ] store this elsewhere and remove it from the queue
            - [ ] if originated from `constant` treate it accordingly
    - [ ] leave any other CVs in the queue, which leaves ...
        - [ ] locally defined subroutines
        - [ ] locally defined anon/my CVs

- [ ] process the CV queue until it is empty
    - NOTE: it is possible during this processing we will add more CVs to the
            end of the queue, so the algorithm should handle that accordingly

    - [ ] infer some misc. information about the subroutine
        - [ ] is it a closure?
        - [ ] does it have any attributes attached to it?
        - [ ] is it an XS sub?

    - [ ] extract the PAD
        - [ ] find any my/anon subroutines
            - [ ] add these to the CV to be processed
        - [ ] find any aliased `our` variables
        - [ ] find any vars which refer to outer pads (closures?)

    - [ ] walk the optree and ...

        - Collect any internal & external dependencies
            - [ ] find any imported subroutines that are called
                - [ ] the `entersub` will end with a `gv`
                    - [ ] which we should then be able correlate with imported subroutines
            - [ ] find any folded constants that has been used
                - [ ] the `const` op will have a `sv`
                    - [ ] which should match with the `sv` from `XSUBANY` from imported constants
            - [ ] find all inter module subroutine calls
            - [ ] find all method calls
                - [ ] distinguish between class/object method calls
                    - [ ] determine constructor calls where possible
                - [ ] note all class usage that can be inferred

        - Collect information about the code, such as ...
            - [ ] does it call `bless`?
                - is it a constructor? can we consider the package a class?
                - can we infer the object repr from bless?
            - [ ] does it do anything dangerous/unwise/tricky?
                - string evals? glob/stash alteration? runtime code loading?
            - [ ] does it throw/catch exceptions?
                - [ ] native try/catch, eval and die
                - [ ] handle standard modules like Carp (and maybe Try::Tiny?)
            - [ ] if the first arg `$self` perhaps it is a method?
                - [ ] does it call methods locally defined?
                - [ ] does it seem to access fields of itself?
                - [ ] can we find a constructor?








