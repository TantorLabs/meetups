#ifndef CONSTRECXL_H
#define CONSTRECXL_H

#include "nodes/primnodes.h"
#include "nodes/pathnodes.h"

extern bool is_mutually_exclusive(OpExpr *left, OpExpr *right);
extern void collapse_mutually_exclusive_quals(PlannerInfo *info);

#endif