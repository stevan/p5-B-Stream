
use v5.40;

use B::Stream::Functional::Consumer;

package B::Stream::Tools::Events {

    sub OnStatementChange {
        return B::Stream::Functional::Predicate->new(
            f => sub ($op) {
                state $curr_stmt;
                # keep assigning it until we get something
                if (not(defined $curr_stmt) && defined $op->statement) {
                    $curr_stmt = $op->statement;
                    return true;
                }
                # return false if we get nothing ...
                return false unless $curr_stmt;

                if ($curr_stmt->addr != $op->statement->addr) {
                    $curr_stmt = $op->statement;
                    return true;
                }

                return false;
            }
        )
    }


}
