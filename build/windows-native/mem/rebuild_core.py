# Rebuild compiler/stage1/runtime_core.lume from the last commit: the regenerated Win64 layer lines and the rt_crypto
# change of the working copy, then the exact removal of every routine that compiler/stage1/rt/*.src now defines in
# Lume. A routine is cut inside its own `fn` line only (each runtime fn is one line): it ends at the next global label
# of that line, at a nested call (`" + rt_x()`), or at the end of the line. Usage: rebuild_core.py <head> <current>
import sys, re, glob
B = chr(92)
head_path, cur_path = sys.argv[1], sys.argv[2]
head = open(head_path, encoding='utf-8').read().split("\n")
cur = open(cur_path, encoding='utf-8').read().split("\n")
def fnname(l):
    m = re.match(r'fn ([A-Za-z_0-9]+)\(', l)
    return m.group(1) if m else None
curmap = {fnname(l): l for l in cur if fnname(l)}
out = []
for l in head:
    n = fnname(l)
    if n in ("rt_win64_layer", "rt_win64_imports") and n in curmap:
        l = curmap[n]
    if n == "rt_crypto" and not l.startswith('fn rt_crypto() = rt_lume_crypto()'):
        l = l.replace('fn rt_crypto() = "crypto_sha256_blocks:', 'fn rt_crypto() = rt_lume_crypto() + "crypto_sha256_blocks:', 1)
    out.append(l)
lume = set()
for f in glob.glob(r'L:\lume\compiler\stage1\rt\*.src'):
    lume |= set(re.findall(r'^fn ([A-Za-z_][A-Za-z0-9_]*)\(', open(f, encoding='utf-8').read(), re.M))
lab = re.compile(r'"([A-Za-z_][A-Za-z0-9_]*):' + re.escape(B) + 'n"')
call = re.compile(r'" \+ [a-z_][a-z_0-9]*\(\)')
removed = []
for idx, l in enumerate(out):
    n = fnname(l)
    if not n or n.startswith("rt_win64"):
        continue
    while True:
        hit = None
        for m in lab.finditer(l):
            if m.group(1) in lume:
                hit = m; break
        if not hit:
            break
        a = hit.start()
        nxt = lab.search(l, a + 3)
        c = call.search(l, a + 3)
        ends = [x.start() for x in (nxt, c) if x]
        if c and (not nxt or c.start() < nxt.start()):
            end = c.start() + 4          # keep `rt_x()`: cut the routine and its `" + `, the call stays
        elif nxt:
            end = nxt.start()
        else:
            end = len(l)
        seg = l[a:end]
        if end == len(l):
            # the routine closes the fn: drop the ` + ` before it, or leave "" when it was the whole body
            pre = l[:a]
            if pre.endswith(" + "):
                l = pre[:-3]
            else:
                l = pre + '""'
        else:
            l = l[:a] + l[end:]
        removed.append(hit.group(1))
    out[idx] = l
text = "\n".join(out)
# every .L label a removed routine defined must not be used any more
defs_left = set(re.findall(r'"(\.L[A-Za-z0-9_]+):' + re.escape(B) + 'n"', text))
used = set(re.findall(r'(\.L[A-Za-z0-9_]+)', text))
dangling = sorted(x for x in used - defs_left if not x.startswith(".Lrw_"))
open(cur_path, 'w', encoding='utf-8', newline='\n').write(text)
print("removed", len(removed), sorted(removed))
print("fn list same as head:", [fnname(l) for l in out if fnname(l)] == [fnname(l) for l in head if fnname(l)])
print("labels used but not defined (should be only data/bss labels defined elsewhere):", dangling[:40])
