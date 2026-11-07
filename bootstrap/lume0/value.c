#include "value.h"
#include <setjmp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---------- Stage-0 heap ----------
 * Interpreting the compiler allocates far more than it keeps, so a grow-only arena needs a dozen
 * gigabytes to bootstrap. This is a non-moving, conservative mark-sweep collector, portable C11:
 *   - small objects live in 64 KiB chunks of one size class, carved from 16 MiB aligned slabs,
 *     found from any interior pointer through a hash table of slabs;
 *   - large objects are single malloc blocks in an address-sorted table;
 *   - roots are the C stack, with the registers spilled into it, and the tables `roots` names;
 *   - AST, interned names and scalar constants are immortal and never enter this heap. */
#define CHUNK_SIZE   ((size_t)65536)
#define SLAB_CHUNKS  256
#define SLAB_SIZE    (CHUNK_SIZE * SLAB_CHUNKS)
#define MAX_SMALL    ((size_t)16384)
#define NCLASS       48
#define GC_FLOOR     ((size_t)134217728)

typedef struct Chunk { uint32_t size, nobj; bool atomic; unsigned char marks[]; } Chunk;
typedef struct Slab  { uintptr_t base; void *raw; unsigned char used[SLAB_CHUNKS]; } Slab;
typedef struct { char *p; size_t n; bool atomic, marked; } Large;
typedef struct { uintptr_t lo, hi; } Range;

static size_t   class_size[NCLASS];
static unsigned char class_of[MAX_SMALL / 8 + 2];
static void    *free_list[2][NCLASS];
static Slab   **slabs;              /* open-addressed by base >> 24 */
static size_t   slab_cap, slab_n;
static Slab   **slab_order;         /* the same slabs, for sweeping */
static Chunk  **free_chunks;
static size_t   free_n, free_cap;
static Large   *larges;
static size_t   large_n, large_cap;
static Range   *mark_stack;
static size_t   mark_n, mark_cap;
static uintptr_t heap_lo = UINTPTR_MAX, heap_hi;
static size_t   allocated, threshold = GC_FLOOR, live_bytes;
static const char *stack_top;
static void (*extra_roots)(void);

static void die_oom(void) { fputs("lume0: out of memory\n", stderr); exit(12); }
static void *xmalloc(size_t n) { void *p = malloc(n); if (!p) die_oom(); return p; }
static void *xrealloc(void *o, size_t n) { void *p = realloc(o, n); if (!p) die_oom(); return p; }

static Slab *slab_find(uintptr_t base) {
    if (!slab_cap) return NULL;
    for (size_t i = (base >> 24) * 0x9E3779B1u & (slab_cap - 1);; i = (i + 1) & (slab_cap - 1)) {
        if (!slabs[i]) return NULL;
        if (slabs[i]->base == base) return slabs[i];
    }
}
static void slab_insert(Slab *s) {
    size_t i = (s->base >> 24) * 0x9E3779B1u & (slab_cap - 1);
    while (slabs[i]) i = (i + 1) & (slab_cap - 1);
    slabs[i] = s;
}
static void slab_add(void) {
    if ((slab_n + 1) * 2 > slab_cap) {
        size_t oc = slab_cap; Slab **old = slabs;
        slab_cap = oc ? oc * 2 : 64;
        slabs = calloc(slab_cap, sizeof *slabs); if (!slabs) die_oom();
        for (size_t i = 0; i < oc; i++) if (old[i]) slab_insert(old[i]);
        free(old);
    }
    Slab *s = xmalloc(sizeof *s); memset(s, 0, sizeof *s);
    s->raw = xmalloc(SLAB_SIZE * 2);     /* the untouched half costs address space only */
    s->base = ((uintptr_t)s->raw + SLAB_SIZE - 1) & ~(uintptr_t)(SLAB_SIZE - 1);
    slab_insert(s);
    slab_order = xrealloc(slab_order, (slab_n + 1) * sizeof *slab_order);
    slab_order[slab_n++] = s;
    if (slab_n * SLAB_CHUNKS > free_cap) { free_cap = slab_n * SLAB_CHUNKS * 2; free_chunks = xrealloc(free_chunks, free_cap * sizeof *free_chunks); }
    for (size_t i = SLAB_CHUNKS; i > 0; i--) free_chunks[free_n++] = (Chunk *)(s->base + (i - 1) * CHUNK_SIZE);
    if (s->base < heap_lo) heap_lo = s->base;
    if (s->base + SLAB_SIZE > heap_hi) heap_hi = s->base + SLAB_SIZE;
}
static size_t chunk_first(const Chunk *c) { return (offsetof(Chunk, marks) + (size_t)c->nobj + 7) & ~(size_t)7; }
static void class_refill(int atomic, int cls) {
    if (!free_n) slab_add();
    Chunk *c = free_chunks[--free_n];
    Slab *s = slab_find((uintptr_t)c & ~(uintptr_t)(SLAB_SIZE - 1));
    s->used[((uintptr_t)c - s->base) / CHUNK_SIZE] = 1;
    size_t size = class_size[cls];
    size_t nobj = (CHUNK_SIZE - offsetof(Chunk, marks) - 8) / (size + 1);
    c->size = (uint32_t)size; c->nobj = (uint32_t)nobj; c->atomic = atomic != 0;
    memset(c->marks, 0, nobj);
    char *first = (char *)c + chunk_first(c);
    void *head = free_list[atomic][cls];
    for (size_t i = nobj; i > 0; i--) { void **o = (void **)(first + (i - 1) * size); *o = head; head = o; }
    free_list[atomic][cls] = head;
}

/* ---------- mark ---------- */
static void push_range(uintptr_t lo, uintptr_t hi) {
    if (mark_n == mark_cap) { mark_cap = mark_cap ? mark_cap * 2 : 4096; mark_stack = xrealloc(mark_stack, mark_cap * sizeof *mark_stack); }
    mark_stack[mark_n].lo = lo; mark_stack[mark_n].hi = hi; mark_n++;
}
static void mark_large(uintptr_t p) {
    size_t lo = 0, hi = large_n;
    while (lo < hi) { size_t m = (lo + hi) / 2; if ((uintptr_t)larges[m].p <= p) lo = m + 1; else hi = m; }
    if (lo == 0) return;
    Large *l = &larges[lo - 1];
    if (p >= (uintptr_t)l->p + l->n || l->marked) return;
    l->marked = true; live_bytes += l->n;
    if (!l->atomic) push_range((uintptr_t)l->p, (uintptr_t)l->p + l->n);
}
static void mark_word(uintptr_t p) {
    if (p < heap_lo || p >= heap_hi) return;
    Slab *s = slab_find(p & ~(uintptr_t)(SLAB_SIZE - 1));
    if (!s) { mark_large(p); return; }
    size_t idx = (p - s->base) / CHUNK_SIZE;
    if (!s->used[idx]) return;
    Chunk *c = (Chunk *)(s->base + idx * CHUNK_SIZE);
    size_t first = chunk_first(c), off = p - (uintptr_t)c;
    if (off < first) return;
    size_t i = (off - first) / c->size;
    if (i >= c->nobj || c->marks[i]) return;
    c->marks[i] = 1; live_bytes += c->size;
    if (!c->atomic) { uintptr_t o = (uintptr_t)c + first + i * c->size; push_range(o, o + c->size); }
}
#if defined(__SANITIZE_ADDRESS__)
#define NO_ASAN __attribute__((no_sanitize("address")))
#elif defined(__has_feature)
#if __has_feature(address_sanitizer)
#define NO_ASAN __attribute__((no_sanitize("address")))
#endif
#endif
#ifndef NO_ASAN
#define NO_ASAN
#else
/* The collector finds roots on the real stack; ASan's fake stack would hide them. */
const char *__asan_default_options(void);
const char *__asan_default_options(void) { return "detect_stack_use_after_return=0"; }
#endif
NO_ASAN void gc_scan_range(const void *lo, const void *hi) {
    uintptr_t a = ((uintptr_t)lo + 7) & ~(uintptr_t)7, w;
    for (; a + 8 <= (uintptr_t)hi; a += 8) { memcpy(&w, (const void *)a, sizeof w); mark_word(w); }
}
static void mark_drain(void) {
    while (mark_n) { Range r = mark_stack[--mark_n]; gc_scan_range((const void *)r.lo, (const void *)r.hi); }
}

/* ---------- sweep ---------- */
static void sweep(void) {
    memset(free_list, 0, sizeof free_list);
    for (size_t si = 0; si < slab_n; si++) {
        Slab *s = slab_order[si];
        for (size_t idx = 0; idx < SLAB_CHUNKS; idx++) {
            if (!s->used[idx]) continue;
            Chunk *c = (Chunk *)(s->base + idx * CHUNK_SIZE);
            size_t size = c->size, live = 0;
            for (size_t i = 0; i < c->nobj; i++) live += c->marks[i];
            if (!live) { s->used[idx] = 0; free_chunks[free_n++] = c; continue; }
            char *first = (char *)c + chunk_first(c);
            int cls = class_of[(size + 7) / 8], atomic = c->atomic;
            void *head = free_list[atomic][cls];
            for (size_t i = c->nobj; i > 0; i--) {
                if (c->marks[i - 1]) { c->marks[i - 1] = 0; continue; }
                void **o = (void **)(first + (i - 1) * size); *o = head; head = o;
            }
            free_list[atomic][cls] = head;
        }
    }
    size_t w = 0;
    for (size_t i = 0; i < large_n; i++) {
        if (larges[i].marked) { larges[i].marked = false; larges[w++] = larges[i]; }
        else free(larges[i].p);
    }
    large_n = w;
}
/* setjmp spills the callee-saved registers into a frame this scan can see; glibc mangles some of
   them there, so where the compiler can do it properly, the registers are saved in this frame too. */
NO_ASAN static void collect_now(void) {
    jmp_buf regs;
#if defined(__GNUC__)
    __builtin_unwind_init();
#endif
    if (setjmp(regs) != 0) return;
    live_bytes = 0;
    char here = 0;
    gc_scan_range((uintptr_t)&here < (uintptr_t)&regs ? (const void *)&here : (const void *)&regs, stack_top);
    if (extra_roots) extra_roots();
    mark_drain();
    sweep();
    allocated = 0;
    threshold = live_bytes > GC_FLOOR ? live_bytes : GC_FLOOR;
}

void gc_init(void *stack_base, void (*roots)(void)) {
    stack_top = stack_base;
    extra_roots = roots;
    size_t size = 16, step = 8;
    int n = 0;
    while (size < MAX_SMALL) {
        class_size[n++] = size;
        size_t next = size + step;
        if (next >= step * 8) step *= 2;
        size = next;
    }
    class_size[n++] = MAX_SMALL;
    for (int c = 0, i = 0; i < (int)(MAX_SMALL / 8 + 2); i++) {
        while (c < n - 1 && class_size[c] < (size_t)i * 8) c++;
        class_of[i] = (unsigned char)c;
    }
}
void gc_shutdown(void) {
    for (size_t i = 0; i < slab_n; i++) { free(slab_order[i]->raw); free(slab_order[i]); }
    for (size_t i = 0; i < large_n; i++) free(larges[i].p);
    free(slabs); free(slab_order); free(free_chunks); free(larges); free(mark_stack);
    slabs = NULL; slab_order = NULL; free_chunks = NULL; larges = NULL; mark_stack = NULL;
    slab_cap = slab_n = free_n = free_cap = large_n = large_cap = mark_n = mark_cap = 0;
    memset(free_list, 0, sizeof free_list);
}
static void *heap_alloc(size_t n, int atomic) {
    if (allocated >= threshold) collect_now();
    if (n > MAX_SMALL) {
        if (large_n == large_cap) { large_cap = large_cap ? large_cap * 2 : 64; larges = xrealloc(larges, large_cap * sizeof *larges); }
        char *p = calloc(1, n); if (!p) die_oom();
        /* keep the table sorted: a collection can start before the next allocation returns */
        size_t i = large_n++;
        while (i > 0 && (uintptr_t)larges[i - 1].p > (uintptr_t)p) { larges[i] = larges[i - 1]; i--; }
        larges[i].p = p; larges[i].n = n; larges[i].atomic = atomic != 0; larges[i].marked = false;
        allocated += n;
        if ((uintptr_t)p < heap_lo) heap_lo = (uintptr_t)p;
        if ((uintptr_t)p + n > heap_hi) heap_hi = (uintptr_t)p + n;
        return p;
    }
    int cls = class_of[(n + 7) / 8];
    if (!free_list[atomic][cls]) class_refill(atomic, cls);
    void **o = free_list[atomic][cls];
    free_list[atomic][cls] = *o;
    memset(o, 0, class_size[cls]);
    allocated += class_size[cls];
    return o;
}
/* A loop may keep only its one-past-the-end pointer alive, so arrays get one extra byte. */
void *lume_rt_alloc(Interp *ip, size_t n) { (void)ip; return heap_alloc(n + 1, 0); }
void *lume_rt_alloc_atomic(Interp *ip, size_t n) { (void)ip; return heap_alloc(n + 1, 1); }

/* ---------- values ---------- */
static Val imm_unit, imm_true, imm_false;
#define SMALL_MIN (-16)
#define SMALL_MAX 1024
static Val imm_int[SMALL_MAX - SMALL_MIN + 1];

Val *v_new(Interp *ip, VKind k) {
    (void)ip;
    Val *v = heap_alloc(sizeof *v, 0);
    v->kind = k;
    return v;
}
Val *v_unit(Interp *ip)             { (void)ip; imm_unit.kind = V_UNIT; return &imm_unit; }
Val *v_bool(Interp *ip, bool b)     { (void)ip; Val *v = b ? &imm_true : &imm_false; v->kind = V_BOOL; v->b = b; return v; }
Val *v_int(Interp *ip, long long i) {
    if (i >= SMALL_MIN && i <= SMALL_MAX) { Val *v = &imm_int[i - SMALL_MIN]; v->kind = V_INT; v->i = i; return v; }
    Val *v = v_new(ip, V_INT); v->i = i; return v;
}
Val *v_float(Interp *ip, double f)  { Val *v = v_new(ip, V_FLOAT); v->f = f; return v; }
Val *v_dec(Interp *ip, long long u, int s) { Val *v = v_new(ip, V_DEC); v->i = u; v->scale = s; return v; }
Val *v_char(Interp *ip, unsigned cp){ Val *v = v_new(ip, V_CHAR); v->i = (long long)cp; return v; }

Val *v_str_owned(Interp *ip, char *s, int len) { Val *v = v_new(ip, V_STR); v->s = s; v->slen = len; return v; }
Val *v_str(Interp *ip, const char *s, int len) {
    char *buf = lume_rt_alloc_atomic(ip, (size_t)len + 1);
    if (len) memcpy(buf, s, (size_t)len);
    buf[len] = 0;
    return v_str_owned(ip, buf, len);
}
Val *v_list(Interp *ip) { return v_new(ip, V_LIST); }
Val *v_opt_some(Interp *ip, Val *x) { Val *v = v_new(ip, V_OPT); v->b = true; v->inner = x; return v; }
Val *v_opt_none(Interp *ip)         { Val *v = v_new(ip, V_OPT); v->b = false; return v; }
Val *v_ok(Interp *ip, Val *x)       { Val *v = v_new(ip, V_RESULT); v->b = true; v->inner = x; return v; }
Val *v_err(Interp *ip, Val *x)      { Val *v = v_new(ip, V_RESULT); v->b = false; v->inner = x; return v; }

void v_push(Interp *ip, Val *list, Val *item) {
    if (list->n == list->cap) {
        int nc = list->cap ? list->cap * 2 : 8;
        Val **ni = lume_rt_alloc(ip, (size_t)nc * sizeof(Val *));
        if (list->items) memcpy(ni, list->items, (size_t)list->n * sizeof(Val *));
        list->items = ni; list->cap = nc;
    }
    list->items[list->n++] = item;
}

/* ---------- environment ---------- */
struct Env { Env *parent; Entry *ent; int n, cap; };

Env *env_new(Interp *ip, Env *parent) {
    Env *e = lume_rt_alloc(ip, sizeof *e);
    memset(e, 0, sizeof *e);
    e->parent = parent;
    return e;
}
static bool name_eq(const Entry *en, const char *name, int len) {
    return en->klen == len && memcmp(en->key, name, (size_t)len) == 0;
}
Val **env_slot(Env *e, const char *name, int len) {
    for (; e; e = e->parent)
        for (int i = 0; i < e->n; i++)
            if (name_eq(&e->ent[i], name, len)) return &e->ent[i].val;
    return NULL;
}
Val *env_get(Env *e, const char *name, int len) {
    Val **s = env_slot(e, name, len);
    return s ? *s : NULL;
}
void env_define(Interp *ip, Env *e, const char *name, int len, Val *v) {
    for (int i = 0; i < e->n; i++)                 /* shadow in same scope => overwrite */
        if (name_eq(&e->ent[i], name, len)) { e->ent[i].val = v; return; }
    if (e->n == e->cap) {
        int nc = e->cap ? e->cap * 2 : 8;
        Entry *ne = lume_rt_alloc(ip, (size_t)nc * sizeof(Entry));
        if (e->ent) memcpy(ne, e->ent, (size_t)e->n * sizeof(Entry));
        e->ent = ne; e->cap = nc;
    }
    e->ent[e->n].key = name; e->ent[e->n].klen = len; e->ent[e->n].val = v;
    e->n++;
}

/* ---------- equality / truthiness ---------- */
bool val_truthy(Val *v) {
    switch (v->kind) {
    case V_BOOL: return v->b;
    case V_OPT:  return v->b;
    case V_UNIT: return false;
    default: return true;
    }
}
static double num_as_double(Val *v) {
    if (v->kind == V_INT) return (double)v->i;
    if (v->kind == V_FLOAT) return v->f;
    long long p = 1; for (int i = 0; i < v->scale; i++) p *= 10;
    return (double)v->i / (double)p;
}
bool val_equal(Val *a, Val *b) {
    bool an = a->kind==V_INT||a->kind==V_FLOAT||a->kind==V_DEC;
    bool bn = b->kind==V_INT||b->kind==V_FLOAT||b->kind==V_DEC;
    if (a->kind != b->kind) {
        if (an && bn) return num_as_double(a) == num_as_double(b);
        return false;
    }
    switch (a->kind) {
    case V_UNIT: return true;
    case V_BOOL: return a->b == b->b;
    case V_INT: case V_CHAR: return a->i == b->i;
    case V_FLOAT: return a->f == b->f;
    case V_DEC: {
        long long ax = a->i, bx = b->i; int sa = a->scale, sb = b->scale;
        while (sa < sb) { ax *= 10; sa++; } while (sb < sa) { bx *= 10; sb++; }
        return ax == bx;
    }
    case V_STR: return a->slen == b->slen && memcmp(a->s, b->s, (size_t)a->slen) == 0;
    case V_OPT: return a->b == b->b && (!a->b || val_equal(a->inner, b->inner));
    case V_RESULT: return a->b == b->b && val_equal(a->inner, b->inner);
    case V_LIST: case V_TUPLE: case V_SET:
        if (a->n != b->n) return false;
        for (int i = 0; i < a->n; i++) if (!val_equal(a->items[i], b->items[i])) return false;
        return true;
    case V_VARIANT:
        if (a->tag != b->tag && strcmp(a->tag ? a->tag : "", b->tag ? b->tag : "")) return false;
        if (a->n != b->n) return false;
        for (int i = 0; i < a->n; i++) if (!val_equal(a->items[i], b->items[i])) return false;
        return true;
    default: return a == b;
    }
}

/* ---------- Show ---------- */
typedef struct { char *buf; int len, cap; Interp *ip; } SB;
static void sb_put(SB *sb, const char *s, int n) {
    if (sb->len + n + 1 > sb->cap) {
        int nc = sb->cap ? sb->cap * 2 : 64;
        while (nc < sb->len + n + 1) nc *= 2;
        char *nb = lume_rt_alloc_atomic(sb->ip, (size_t)nc);
        if (sb->buf) memcpy(nb, sb->buf, (size_t)sb->len);
        sb->buf = nb; sb->cap = nc;
    }
    memcpy(sb->buf + sb->len, s, (size_t)n); sb->len += n; sb->buf[sb->len] = 0;
}
static void sb_puts(SB *sb, const char *s) { sb_put(sb, s, (int)strlen(s)); }
static void sb_fmt(SB *sb, const char *fmt, long long x) { char t[32]; int n = snprintf(t, sizeof t, fmt, x); sb_put(sb, t, n); }

static void dec_to_sb(SB *sb, long long units, int scale) {
    char tmp[64];
    bool neg = units < 0; unsigned long long u = neg ? (unsigned long long)(-units) : (unsigned long long)units;
    int n = snprintf(tmp, sizeof tmp, "%llu", u);
    if (neg) sb_puts(sb, "-");
    if (scale == 0) { sb_put(sb, tmp, n); return; }
    if (n <= scale) { sb_puts(sb, "0."); for (int i = 0; i < scale - n; i++) sb_puts(sb, "0"); sb_put(sb, tmp, n); }
    else { sb_put(sb, tmp, n - scale); sb_puts(sb, "."); sb_put(sb, tmp + (n - scale), scale); }
}

static void show(SB *sb, Val *v) {
    char t[64];
    switch (v->kind) {
    case V_UNIT: sb_puts(sb, "()"); break;
    case V_BOOL: sb_puts(sb, v->b ? "true" : "false"); break;
    case V_INT: sb_fmt(sb, "%lld", v->i); break;
    case V_FLOAT: { int n = snprintf(t, sizeof t, "%g", v->f); sb_put(sb, t, n); break; }
    case V_DEC: dec_to_sb(sb, v->i, v->scale); break;
    case V_CHAR: {
        unsigned cp = (unsigned)v->i;
        if (cp < 0x80) { char c = (char)cp; sb_put(sb, &c, 1); }
        else if (cp < 0x800) { char b[2] = { (char)(0xC0|(cp>>6)), (char)(0x80|(cp&0x3F)) }; sb_put(sb, b, 2); }
        else if (cp < 0x10000) { char b[3] = { (char)(0xE0|(cp>>12)), (char)(0x80|((cp>>6)&0x3F)), (char)(0x80|(cp&0x3F)) }; sb_put(sb, b, 3); }
        else { char b[4] = { (char)(0xF0|(cp>>18)), (char)(0x80|((cp>>12)&0x3F)), (char)(0x80|((cp>>6)&0x3F)), (char)(0x80|(cp&0x3F)) }; sb_put(sb, b, 4); }
        break;
    }
    case V_STR: sb_put(sb, v->s, v->slen); break;
    case V_OPT: if (v->b) { sb_puts(sb, "some("); show(sb, v->inner); sb_puts(sb, ")"); } else sb_puts(sb, "none"); break;
    case V_RESULT: sb_puts(sb, v->b ? "ok(" : "err("); show(sb, v->inner); sb_puts(sb, ")"); break;
    case V_LIST: case V_SET: {
        sb_puts(sb, v->kind == V_SET ? "{" : "[");
        for (int i = 0; i < v->n; i++) { if (i) sb_puts(sb, ", "); show(sb, v->items[i]); }
        sb_puts(sb, v->kind == V_SET ? "}" : "]");
        break;
    }
    case V_TUPLE: {
        sb_puts(sb, "(");
        for (int i = 0; i < v->n; i++) { if (i) sb_puts(sb, ", "); show(sb, v->items[i]); }
        sb_puts(sb, ")");
        break;
    }
    case V_MAP: {
        sb_puts(sb, "{");
        for (int i = 0; i < v->nent; i++) { if (i) sb_puts(sb, ", "); sb_put(sb, v->ent[i].key, v->ent[i].klen); sb_puts(sb, ": "); show(sb, v->ent[i].val); }
        sb_puts(sb, "}");
        break;
    }
    case V_RECORD: {
        sb_puts(sb, v->tname ? v->tname : "record"); sb_puts(sb, "(");
        for (int i = 0; i < v->nent; i++) { if (i) sb_puts(sb, ", "); sb_put(sb, v->ent[i].key, v->ent[i].klen); sb_puts(sb, ": "); show(sb, v->ent[i].val); }
        sb_puts(sb, ")");
        break;
    }
    case V_VARIANT: {
        sb_puts(sb, v->tag ? v->tag : "?");
        if (v->n) { sb_puts(sb, "("); for (int i = 0; i < v->n; i++) { if (i) sb_puts(sb, ", "); show(sb, v->items[i]); } sb_puts(sb, ")"); }
        break;
    }
    case V_RANGE: { sb_fmt(sb, "%lld", v->lo); sb_puts(sb, v->inc ? "..=" : ".."); sb_fmt(sb, "%lld", v->hi); break; }
    case V_CLOSURE: sb_puts(sb, "<closure>"); break;
    case V_BUILTIN: sb_puts(sb, "<builtin "); sb_puts(sb, v->bname ? v->bname : "?"); sb_puts(sb, ">"); break;
    case V_FIELDACC: sb_puts(sb, "<.accessor>"); break;
    case V_TYPE: sb_puts(sb, v->tname ? v->tname : "<type>"); break;
    }
}

char *val_to_cstr(Interp *ip, Val *v, int *out_len) {
    SB sb = { .ip = ip };
    show(&sb, v);
    if (!sb.buf) { sb.buf = lume_rt_alloc_atomic(ip, 1); sb.buf[0] = 0; sb.len = 0; }
    if (out_len) *out_len = sb.len;
    return sb.buf;
}
