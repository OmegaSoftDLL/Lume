/* Runtime values for the Stage-0 interpreter. Boxed: every Val* is either collected heap memory
 * or an immortal (AST-arena / static) constant. See "Stage-0 heap" in value.c. */
#ifndef LUME0_VALUE_H
#define LUME0_VALUE_H
#include "ast.h"
#include <stdbool.h>
#include <stddef.h>

typedef enum {
    V_UNIT, V_BOOL, V_INT, V_FLOAT, V_DEC, V_CHAR, V_STR,
    V_LIST, V_SET, V_TUPLE, V_MAP, V_RECORD, V_VARIANT,
    V_OPT, V_RESULT, V_RANGE, V_CLOSURE, V_BUILTIN, V_FIELDACC, V_TYPE
} VKind;

typedef struct Val Val;
typedef struct Env Env;
typedef struct Interp Interp;

typedef struct { const char *key; int klen; Val *val; } Entry;

/* 64 bytes. The payload unions overlay fields that no single kind uses together; the int counters
   and `tname` stay separate because generic code reads them on values of any kind. */
struct Val {
    VKind kind;
    union {
        int slen;       /* V_STR */
        int scale;      /* V_DEC: number of fractional digits */
        int facc_len;   /* V_FIELDACC */
    };
    int n, cap;         /* list/set/tuple items, variant payload; V_STR: cap = cached codepoints + 1 */
    int nent, cent;     /* map / record fields */
    const char *tname;  /* type name (record/variant/type) */
    union {
        long long i;    /* V_INT; V_DEC units; V_CHAR codepoint */
        double    f;    /* V_FLOAT */
        char     *s;    /* V_STR */
        Val     **items;
        Entry    *ent;
        Val      *inner;   /* opt/result */
        long long lo;      /* range */
        const Node *cl_params_owner; /* the N_FN or N_CLOSURE node (for params/body) */
        Val *(*builtin)(Interp *, Val **args, int nargs, const Node *site);
        const char *facc;  /* fieldacc: the field name */
    };
    union {
        long long hi;      /* range */
        char    **names;   /* variant: optional payload names, parallel to items */
        Env      *cl_env;
        const char *bname; /* builtin */
    };
    union {
        const char *tag;     /* variant tag */
        const char *cl_name;
    };
    bool b;             /* V_BOOL; V_OPT is_some; V_RESULT is_ok */
    bool inc;           /* range */
    bool is_closure_fn; /* true if from N_FN (params are N_PARAM kids) */
};

/* control-flow signal threaded through evaluation */
typedef enum { FL_NORMAL, FL_RETURN, FL_BREAK, FL_CONTINUE, FL_FAIL, FL_PANIC } Flow;

struct Interp {
    Arena      *a;          /* immortal arena: AST, interned names, constant values */
    DiagList   *d;
    const char *file;
    Env        *globals;
    /* control-flow carrier */
    Flow        flow;
    Val        *signal;     /* return/break value, or fail/panic payload */
    const char *brk_label;
    Env        *old_env;    /* snapshot for old() in ensures */
    int         exit_code;
    bool        had_runtime_error;
};

/* heap: conservative mark-sweep. `stack_base` is an address above every frame that holds a value;
   `roots` marks what lives outside the stack and the heap, through gc_scan_range. */
void  gc_init(void *stack_base, void (*roots)(void));
void  gc_shutdown(void);
void  gc_scan_range(const void *lo, const void *hi);
void *lume_rt_alloc(Interp *ip, size_t n);          /* zeroed; scanned for pointers */
void *lume_rt_alloc_atomic(Interp *ip, size_t n);   /* zeroed; never holds pointers */

/* constructors. Scalars may be shared immortal constants: to fill a value in by hand use v_new. */
Val *v_new(Interp *, VKind);
Val *v_unit(Interp *);
Val *v_bool(Interp *, bool);
Val *v_int(Interp *, long long);
Val *v_float(Interp *, double);
Val *v_dec(Interp *, long long units, int scale);
Val *v_char(Interp *, unsigned cp);
Val *v_str(Interp *, const char *s, int len);
Val *v_str_owned(Interp *, char *s, int len);
Val *v_list(Interp *);
Val *v_opt_some(Interp *, Val *);
Val *v_opt_none(Interp *);
Val *v_ok(Interp *, Val *);
Val *v_err(Interp *, Val *);
void v_push(Interp *, Val *list, Val *item);

/* environment. Names are not copied: callers pass text that outlives the run (AST or literals). */
Env *env_new(Interp *, Env *parent);
Val *env_get(Env *, const char *name, int len);
Val **env_slot(Env *, const char *name, int len);     /* for assignment; NULL if absent */
void env_define(Interp *, Env *, const char *name, int len, Val *);

/* display */
char *val_to_cstr(Interp *, Val *, int *out_len);       /* Show */
bool  val_equal(Val *, Val *);
bool  val_truthy(Val *);

#endif
