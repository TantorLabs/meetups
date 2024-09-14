#include "postgres.h"

#include "catalog/pg_operator.h"
#include "nodes/makefuncs.h"
#include "nodes/pg_list.h"
#include "optimizer/constrexcl.h"
#include "optimizer/restrictinfo.h"
#include "utils/datum.h"
#include "utils/lsyscache.h"

static bool
extract_operands(OpExpr *expr, Var **out_var, Const **out_const)
{
}

bool
is_mutually_exclusive(OpExpr *left, OpExpr *right)
{
}

static void
collapse_mutually_exclusive_quals_for_rel(PlannerInfo *root, RelOptInfo *rel)
{
}

void
collapse_mutually_exclusive_quals(PlannerInfo *root)
{
}
