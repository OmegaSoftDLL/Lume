# Financial Data, Tensors/GPU Kernels & Bare-Metal Ring-0 Systems

## Table of Contents
1. [Exact Financial Computing (`decimal`, `money`, `persist table`, `query`)](#1-exact-financial-computing-decimal-money-persist-table-query)
2. [AI/ML: Shape-Checked Tensors, Autodiff & GPU Kernels (PTX / SPIR-V)](#2-aiml-shape-checked-tensors-autodiff--gpu-kernels-ptx--spir-v)
3. [Bare-Metal Systems, OS Kernels (`@freestanding`) & Hardware Capabilities](#3-bare-metal-systems-os-kernels-freestanding--hardware-capabilities)
4. [Fail-Closed C & WASM Interoperability (`lume adapt c`)](#4-fail-closed-c--wasm-interoperability-lume-adapt-c)

---

## 1. Exact Financial Computing (`decimal`, `money`, `persist table`, `query`)

Lume eliminates IEEE-754 floating-point rounding errors in financial and SaaS applications by providing first-class fixed-point decimals, currency-tagged money types, and durable write-ahead-logged (WAL) relational tables:

```rust
type InvoiceRow = {
  id: Int,
  tenant_id: Int,
  subtotal: money[BRL],
  tax: money[BRL]
}

// Durable WAL-backed table
persist table invoices: table[InvoiceRow]

fn total_with_tax(subtotal_cents: Int, tax_bps: Int) -> Int
  requires subtotal_cents >= 0 && tax_bps >= 0 && tax_bps <= 10000
  ensures result >= subtotal_cents
{
  subtotal_cents + (subtotal_cents * tax_bps) / 10000
}
```

- **Currency Safety:** Adding `money[BRL]` and `money[USD]` without an explicit FX conversion function is a compile-time type error.
- **Integrated Queries:** Use `query { from r in invoices where r.tenant_id == tid select r }` for type-safe relational queries without SQL injection risks.

---

## 2. AI/ML: Shape-Checked Tensors, Autodiff & GPU Kernels (PTX / SPIR-V)

Lume checks tensor dimensions at compile time (`[T0300] shape mismatch`), computes exact forward/reverse-mode automatic differentiation (`grad`, `value_and_grad`, `jvp`, `vjp`), and lowers `@schedule(...) kernel fn` directly to **CUDA PTX 8.0** and **Vulkan SPIR-V 1.6** without Python or C++ wrappers:

```rust
// Shape-checked matrix multiplication: [B, K] x [K, N] -> [B, N]
fn linear_forward[B: Int, K: Int, N: Int](
  x: tensor[f32, B, K],
  w: tensor[f32, K, N],
  b: tensor[f32, B, N]
) -> tensor[f32, B, N] {
  matmul(x, w) + b
}

// Direct-to-silicon GPU kernel lowered to SSA CUDA PTX 8.0 & Vulkan SPIR-V 1.6
@schedule(grid: 256, block: 128)
kernel fn fused_rmsnorm_silu(ptr_in: Int, ptr_out: Int, n: Int) -> Int {
  let tid = thread_idx_x() + block_idx_x() * block_dim_x()
  if tid < n {
    store_f32(ptr_out + tid * 4, silu(load_f32(ptr_in + tid * 4)))
  }
  0
}
```

To synthesize and compile a verified GPU kernel from a mathematical specification via CLI:
```bash
lume neural-kernel "fused_attention_rmsnorm"
```

---

## 3. Bare-Metal Systems, OS Kernels (`@freestanding`) & Hardware Capabilities

Lume compiles directly to bootable x86-64 MBR + 64-bit Long Mode `.kernel` images (`lasm.src` `asmkernel`) as well as freestanding ELF/PE/Mach-O/RISC-V/Intel-HEX binaries:

```rust
@freestanding
@repr(c)
@packed
type IdtEntry = {
  offset_low: Int,
  selector: Int,
  ist: Int,
  type_attr: Int,
  offset_mid: Int,
  offset_high: Int,
  zero: Int
}

@freestanding
@bound(cycles: 32)
fn cmos_rtc_port_reg(reg: Int) -> Int =
  if reg < 0 then 0
  else if reg > 127 then 127
  else reg
```

- **Linear Hardware Capabilities (`cap[Page]`, `cap[Port]`, `cap[Irq]`):** Hardware I/O ports (`inb`/`outb`), MMIO regions (`@mmio`), and page tables (`CR3`) require linear capability tokens that cannot be forged or duplicated.
- **Interrupt Safety (`@interrupt`):** Interrupt service routines automatically forbid heap allocation, blocking operations, and unbounded loops.

---

## 4. Fail-Closed C & WASM Interoperability (`lume adapt c`)

Lume interoperates with C ABI libraries without header glue:

```rust
extern "c" fn puts(s: String) -> Int

pub extern "c" fn lume_exported_checksum(a: Int, b: Int) -> Int {
  (a * 31) + b
}
```

To automatically generate a fail-closed, contract-checked Lume adapter from a C header:
```bash
lume adapt c include/library.h -o src/library_adapter.lume
```
Any unsafe raw pointer or unchecked buffer in C is isolated behind a fail-closed boundary (`[I0003]`).
