# 44 — macOS Darwin layer and Swift interoperability (design, not yet built)

Status: **design only, now being unblocked.** None of this exists in the tree yet. It requires running
`objc_msgSend`, `dyld`, `codesign`, and `swiftc` for real on Apple hardware — and as of 2026-11-24 the owner is
bringing a Mac onto the Tailscale network for exactly that (the macOS build/validate host, the way `notacer` is the
Acer build host). This is roadmap item **C** (new OS targets) and is the macOS counterpart of the Windows ABI floor
described in `docs/42` §7 and the `win64_layer.s` RUNTIME QUEUE item 7.

Owner directive (2026-11-24): **Lume must emit Swift-compilable output**, and once the macOS compiler exists
*everything must work perfectly* — every function, module and domain, same outputs as Linux/Windows, performance
never below them (the standing parity goal, now extended to the Mac target). This document is the plan that commits to
that.

## 0. The core fact that shapes everything

The chameleon (and Lume's FFI) **does not speak Swift directly**, and must not pretend to. Swift is not a plain
C-ABI library:

- Swift has its own **name mangling** (e.g. `$s4Foo3baryyF`), so a Swift symbol is not resolvable as a clean C name.
- Swift has its own **calling convention** (`swiftcall`): extra dedicated registers for `self`, the type context, and
  the error return; value types are passed through **value witnesses**.
- Swift has its own **runtime** (`libswiftCore`): reference counting, type metadata, protocol witness tables.

So `dlopen` + `dlsym` + generic C marshalling is **not** enough to call a Swift function. Everyone who bridges to
Apple from another language (Rust, Go, C, and this plan for Lume) goes through the **C ABI and the Objective-C
runtime**, plus a thin Swift shim where a Swift-only API has no C/ObjC surface.

## 1. The three layers (mirror of the Windows anchor)

| Windows (exists today) | macOS (this plan) |
|---|---|
| `win64_layer.s`: `__win_start`, `__win_syscall`, `__win_ffi_resolve` | **Darwin floor** `darwin_layer.s`: Mach-O `_start`, BSD/Mach syscall boundary (BSD class `0x2000000`, different numbers), symbol resolver over `dlopen`/`dlsym` (dyld) |
| Win64 calling-convention marshalling (pseudo-calls 1010/1011) | **ABI marshalling**: AArch64 Apple ABI (Apple Silicon; variadics on the stack, Apple struct-passing quirks) and x86-64 System V (Intel Macs) |
| `winsys.src` / `net.src` over `ws_call` | `mac_sys.src` / `cocoa.src` over `objc_msg` (see §2) |

Like the Windows floor and the Linux `_start`/GC thunk, `darwin_layer.s` is **intentional, irreducible ABI-boundary
asm**, not a "migrate to Lume" backlog. Writing the process entry point / syscall boundary in Lume is circular. Above
the floor, the whole macOS surface is ordinary Lume, exactly as `winsys.src` is on Windows.

## 2. Reaching Apple frameworks: the Objective-C runtime

Most Apple frameworks (Foundation, AppKit, CoreGraphics, Metal, AVFoundation, …) are Objective-C or expose a C API.
The entire Objective-C runtime is reachable through three C functions in `libobjc.dylib`, which marshal exactly like
any Win32 call does today:

- `objc_getClass("NSApplication")` → a class object
- `sel_registerName("sharedApplication")` → a selector
- `objc_msgSend(receiver, selector, args…)` → the dispatched call

The Lume surface (`cocoa.src`) wraps these into readable words, analogous to `ws_call`:

```
# concept; does not exist yet
priv fn cls(name)      = objc_get_class(name)
priv fn sel(name)      = sel_register_name(name)
fn ns_shared_app()     = objc_msg0(cls("NSApplication"), sel("sharedApplication"))
```

`objc_msgSend` has ABI subtleties the floor must handle: the `_stret` variant for struct returns on x86-64, the
`_fpret` variant, and the fact that on Apple Silicon `objc_msgSend` is a single entry (no `_stret`). These live in the
marshaller, not in Lume.

## 3. Swift interoperability — the owner's "gerar compilável de swift"

Two directions, both required for "everything works perfectly":

### 3a. Lume called **from** Swift (Lume emits Swift-compilable artifacts)

Lume must produce a C-ABI surface that `swiftc` can import and compile against. Concretely, a `lume build
--target darwin --emit swift-package <lib>.src` produces:

1. **C-ABI exports**: each `pub` Lume function selected for export is emitted with a stable C symbol and C-compatible
   signature (the `@_cdecl` equivalent on the Lume side — a plain, unmangled `extern "C"` symbol).
2. **A C header** (`<lib>.h`) declaring those exports.
3. **A Clang module map** (`module.modulemap`) so Swift can `import <Lib>` directly — this is the standard,
   supported C→Swift bridge; `swiftc` compiles against it with no extra glue.
4. **Optionally, a generated `.swift` shim** (`<lib>.swift`) that wraps the C surface in idiomatic Swift types
   (String/Array bridging, `Error` conformance). This is the literal "generate Swift source that compiles" path:
   Lume writes `.swift` that `swiftc` accepts and builds.

Acceptance: `swiftc` compiles the emitted package with zero warnings, a Swift test program calls every exported Lume
function, and the results are **bit-identical** to the same calls on Linux and Windows (the parity rule, extended to
the Swift caller).

### 3b. Lume calling **into** Swift-only APIs (SwiftUI and friends)

Where an Apple API has no C/ObjC surface (pure SwiftUI, some newer frameworks), Lume generates a tiny **Swift shim**
compiled by `swiftc` into a `.dylib`: the shim exposes `@_cdecl`/`@objc` entry points that the chameleon resolves and
calls like any C symbol. Lume never links Swift's mangled symbols directly; it links the shim's C surface. The shim is
generated from a small interface description, so it stays "Lume generates Lume (plus the minimal foreign shim through
the chameleon)", consistent with the external-via-chameleon rule.

## 4. Emitting the executable

Beyond the FFI, producing a runnable Mac program needs:

- **`lasm --macho`**: Mach-O object/executable emission (today we have ELF for Linux and `--pe` for Windows).
- **Code signing**: on Apple Silicon a binary will not run without at least ad-hoc signing
  (`codesign -s - <bin>`); the toolchain must invoke it (or embed an ad-hoc signature) as part of `lume build`.
- **The Darwin runtime layer** (`darwin_layer.s`) linked in, as §1.
- **Universal binaries** (optional): `arm64` + `x86_64` slices via a Mach-O fat header, if we target both Mac
  architectures.

## 5. Validation plan (the "everything must work perfectly" bar)

When a Mac is available, item C is not done until, on macOS:

1. The frozen-seed battery is **438/0**, byte-identical in outputs to Linux and Windows.
2. The full test universe (`mem/tests_all.txt`) and the programs (`mem/progs_all.txt`) match Linux/Windows
   file-by-file, as the Windows parity run already does (`docs/43-performance-parity.md`).
3. Measured performance on macOS is **not below** Linux (same parity rule).
4. The Swift bridge of §3a compiles under `swiftc` and a Swift caller gets identical results; the §3b shim path runs a
   SwiftUI smoke program.
5. `codesign --verify` passes and the binary launches on a clean Apple Silicon machine.

## 6. Honest status

Nothing here is implemented. The blocker is hardware, not design: `objc_msgSend`, `dyld`, `codesign` and `swiftc`
must be exercised on a real Mac. The `darwin_layer.s` floor is the same irreducible-ABI category as `win64_layer.s`
(roadmap A7); the parts that are Lume (`cocoa.src`, the C/Swift emitters in `lasm`/the driver) are ordinary Lume work
that can be *drafted* on Linux but only *validated* on macOS. Until then this document is the commitment, not a
delivery.
