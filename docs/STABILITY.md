# Stability and versions

This is the promise Lume makes to programs that depend on it, and the rules every release follows.

## 1. Semantic versioning, for real

Versions are `MAJOR.MINOR.PATCH` (`lume --version`).

- **Within 1.x, a program that compiles and passes its tests keeps compiling and passing them.** No builtin, module
  function, keyword, CLI command or diagnostic code that the factual reference (`lume manual ref`) lists as
  **stable** is removed, renamed, or changes its arguments, its result, or its answer to a wrong argument.
- **MINOR** (1.2 → 1.3) adds: new builtins, modules, commands, warnings, optimizations. A new warning never stops a
  build that worked.
- **PATCH** (1.2.0 → 1.2.1) fixes defects and performance only.
- **MAJOR** (2.0) is the only place a stable item may be removed or changed, and only after the deprecation period
  below.
- Items marked **experimental** in the reference may change in a MINOR release; the change is listed in "Changed in
  this version".
- A fix that changes an answer which was wrong (a result that contradicts the reference, the standard a builtin
  implements, or a documented contract) is a defect fix, not a break; it is listed under **Changed**.

## 2. Deprecation before removal

1. The item is marked in the source with a comment directly above the function:

   ```
   ## Deprecated: use buf_h264_luma_mc (same arguments); removed in 2.0
   pub fn old_name(a, b) = ...
   ```

   Every program that calls it from another module gets warning **[W0005]** with that message, on every build. The
   item keeps working unchanged.
2. The reference marks it **deprecated**, with the replacement, and "Changed in this version" lists it.
3. It stays for **at least one whole MINOR release** (marked in 1.3, still there in all of 1.3.x and 1.4.x); it may
   go only in the next MAJOR.

## 3. Every release

- "Changed in this version" in the reference (`lume manual ref`, section 11) and the CHANGELOG list what was
  **added**, **changed** (signature, result, behaviour), **deprecated** and **removed**.
- The builtin regression test (`compiler/stage1/builtins_regress_ok.src`), the reference examples
  (`tests/docs/ref_examples_gate.src`) and the full test suite pass on **Linux and Windows**, built from the same
  commit; both toolchains print the same `lume --version`. A builtin missing from one release fails to compile in the
  regression test, so it cannot ship.
- Linux and Windows are released together.

## 4. Long-term support

- The **1.2** line is the first long-term-support line: it receives defect, security and performance fixes as
  PATCH releases (1.2.1, 1.2.2, ...) for at least 12 months after 1.3.0, without new features. Programs in production
  (such as an agent running as a system service) can stay on 1.2.x and take only fixes.
- Every LTS fix is first made on the main line, then carried to the LTS line with the same tests.

## 5. What is not covered

- Text of diagnostic messages (the codes, such as `[T2001]` or `[W0005]`, are stable; the wording may improve).
- Performance numbers (they only improve; a measured slowdown is a defect).
- Vision and research material (`lume manual vision`).
