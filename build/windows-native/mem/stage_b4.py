# Two-step bootstrap helper for runtime batches whose Lume source needs a primitive the installed lumec lacks
# (sym_addr). "stage": keep the final files aside, write a runtime_core with the old asm of the routines that use the
# new primitive and an rt_fs.src without them. "final": put the final files back.
import sys, re, shutil
B = chr(92)
root = r'L:\lume\compiler\stage1'
core, rtfs = root + r'\runtime_core.lume', root + r'\rt\rt_fs.src'
keep = r'L:\lume\build\windows-native\mem'
names = ["io_read_byte", "os_arg_count", "os_arg_at", "os_platform", "os_getenv", "os_env_has", "rt_envp", "rt_env_find", "os_setenv", "os_unsetenv", "rt_setenv", "rt_setenv_fill", "rt_has_eq", "rt_env_count", "rt_env_keep", "rt_env_scan", "rt_env_match", "rt_up"]
if sys.argv[1] == "stage":
    shutil.copy(core, keep + r'\rc_final.lume'); shutil.copy(rtfs, keep + r'\rt_fs_final.src')
    head = open(keep + r'\rc_head.lume', encoding='utf-8').read()
    s = open(core, encoding='utf-8').read()
    pat = re.compile(r'"([A-Za-z_][A-Za-z0-9_]*):' + re.escape(B) + 'n"')
    segs = ""
    for r in names:
        k = head.find('"' + r + ':' + B + 'n"')
        if k < 0: continue
        m = pat.search(head, k + 3); segs += head[k:m.start()]
    anchor = '"mkint:' + B + 'n"'; i = s.index(anchor); s = s[:i] + segs + s[i:]
    open(core, 'w', encoding='utf-8', newline='\n').write(s)
    t = open(rtfs, encoding='utf-8').read()
    t = "\n".join(l for l in t.split("\n") if not any(l.startswith("fn " + r + "(") for r in names))
    open(rtfs, 'w', encoding='utf-8', newline='\n').write(t)
    print("staged")
else:
    shutil.copy(keep + r'\rc_final.lume', core); shutil.copy(keep + r'\rt_fs_final.src', rtfs); print("final")
