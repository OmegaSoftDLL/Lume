# Lume reach and Reddit campaign

Ready-to-use drafts for a multichannel launch and a six-week, discussion-first Reddit campaign. International copy is in English, with a native Portuguese adaptation for Brazilian communities.

## Positioning

Lume is an experimental, AI-first programming language: AI authors the code, the compiler checks it, and humans review and govern the result. Its strongest verifiable stories are:

- A self-hosted compiler and assembler written in Lume, with a bit-identical `stage 2 == stage 3` bootstrap fixpoint.
- No C compiler, external assembler, or external linker in the steady-state native toolchain. A frozen C seed remains the reproducibility root.
- Structured diagnostics, machine-readable language description, typed holes, contracts, effects, provenance, and MCP tools designed for AI coding agents.
- Sound compile-time proofs for the supported QF_LIA fragment, independent proof-certificate verification, and runtime checks outside that fragment.
- Native interop, multi-target output, and an experimental x86-64 kernel that boots in QEMU.

## Claims to keep honest

- Describe Lume as **experimental**, not production-proven.
- Distinguish the moving `main` branch from the latest tagged release. Do not imply that every feature on `main` is in v0.2.0.
- Say “no C in the steady-state toolchain,” not “the repository contains no C.” The frozen bootstrap seed is C.
- Say “proofs for supported QF_LIA contracts,” not “the compiler proves every program correct.” A proof also does not prove that a specification captures every human requirement.
- Physical GPU driver launch is planned; current PTX/SPIR-V execution uses instruction-level VM emulators.
- `std.wasm` is a reference capability/bounds model, not a real isolated WASM runtime.
- `lume-os` boots in QEMU and has real kernel mechanisms, but it is not yet a general-purpose OS.
- Do not call Lume “the only” toolchain with a capability unless that comparison has been independently verified.

## Campaign rules

1. Read the subreddit’s current rules and self-promotion policy immediately before posting. Rules were not verified when this campaign was drafted.
2. Do not publish all posts at once or cross-post identical text. Use one post per week and adapt if a community asks for a different format.
3. Post as a person, disclose that Lume is AI-authored, and answer technical comments before posting elsewhere.
4. Lead with evidence and a genuine question, not a star request. Never ask for upvotes.
5. If a community rejects self-promotion, do not repost the same content there.
6. Link to the specific documentation or example relevant to each post rather than dropping only a repository link.

## Maximum-reach distribution plan

The objective is maximum **qualified reach**: developers, compiler engineers, AI-tooling users, verification practitioners, and systems programmers. Raw impressions matter less than people who watch a demo, visit the repository, run Lume, or share it with another relevant community.

### Use one launch, many native assets

Do not copy the same link post everywhere. Create one coherent launch and adapt the opening, length, evidence, and call to action to each channel.

**Preparation, 3–5 days before launch:**

- Record a 60–90 second demonstration with captions: install → `lume describe --json` → compile/run → `lume prove` → independent certificate verification. Show actual terminal output; do not simulate results.
- Create a 15-second version for short-form feeds and a 5–10 minute technical walkthrough for YouTube.
- Prepare three images: the native toolchain pipeline, an AI edit → diagnostic → repair loop, and a contract with its proof/counterexample plus certificate verification.
- Add a repository social-preview image and make the first screen of the README answer what Lume is, why it matters, what works, and how to try it.
- Test installation and every command shown in public material from a clean environment. Label whether the demonstration uses v0.2.0 or `main`.
- Prepare a single canonical launch URL. Use channel-specific UTM parameters where supported so referral traffic can be measured.

### Distribution waves

| Timing | Channels | Native angle |
|---|---|---|
| Launch day | Hacker News, r/ProgrammingLanguages, dev.to, X, LinkedIn, Mastodon | Project introduction plus real demo |
| Days 2–4 | r/Compilers, compiler newsletters, relevant Discord/Matrix communities | Self-hosting and bootstrap evidence |
| Days 5–7 | r/brdev, TabNews, Portuguese LinkedIn and YouTube | Brazilian technical introduction, not a translated repost dump |
| Week 2 | AI/developer communities where project posts are allowed | MCP, structured diagnostics, provenance, and proof workflow |
| Weeks 3–6 | r/osdev, verification and systems communities | Kernel and independent-verification deep dives |
| Ongoing | Newsletter curators, podcast guests, conference CFPs, meetups | Technical story backed by new demos and releases |

Only use communities where participation and project posts are allowed. Do not create multiple accounts, coordinate votes, buy engagement, or ask people to repost identical messages. Those tactics can destroy the launch and the account.

### Highest-leverage channels

- **Hacker News:** one strong `Show HN` with a working artifact and fast, substantive answers. This is the highest-potential technical launch post, not a place for marketing language.
- **Reddit:** separate technical discussions for language design, compilers, OS development, and Brazilian developers. Follow each community’s rules.
- **dev.to:** a durable technical article with code, output, architecture diagram, and an honest limitations section.
- **X and Mastodon:** a short thread built around the demo and three surprising technical facts; each post should make sense in a feed.
- **LinkedIn:** the human project story, why AI-authored code needs stronger checking, and a link to the demonstration.
- **YouTube and short video:** the actual workflow is the proof. Use the long video as the source for Shorts and other clips.
- **Portuguese channels:** r/brdev, TabNews, Brazilian developer groups, and Portuguese video/LinkedIn content. Use native Portuguese copy rather than machine-translated English marketing.
- **Curated newsletters and podcasts:** pitch a specific technical story—self-hosting, AI-first diagnostics, or independent proofs—not a generic “new language” announcement.

## Copy for additional channels

### Hacker News

**Title:** Show HN: Lume – An AI-first, self-hosting programming language

**Submission URL:** https://github.com/OmegaSoftDLL/lume

**First comment:**

Hi HN — I’ve been working on Lume, an experimental language designed for AI-authored, human-reviewed code.

The project has three main technical bets:

1. The language teaches itself to a model and exposes structured diagnostics, proofs, witnesses, repairs, and impact analysis as machine-consumable tools.
2. The compiler and assembler are written in Lume. A frozen C seed bootstraps them once, then the bootstrap verifies a bit-identical stage 2/stage 3 fixpoint with no C compiler or external assembler/linker in the steady state.
3. Supported QF_LIA contracts can produce independently verified certificates; unsupported obligations remain runtime-checked rather than being called proven.

Lume is experimental, and the moving `main` branch is ahead of the latest tagged release. I’d particularly appreciate scrutiny of the bootstrap, the AI-authoring workflow, and the certificate design. I’ll be here to answer technical questions.

Only submit as `Show HN` when the linked artifact lets people try the project themselves. Answer comments promptly and do not ask for votes.

### X / Twitter thread

**1/6**

What if a programming language treated AI as the primary author—and humans as reviewers and governors?

That is the idea behind Lume: an experimental, self-hosting language built around machine-checkable code.

Demo + source: https://github.com/OmegaSoftDLL/lume

**2/6**

Lume does not assume a model has seen its syntax in training.

`lume describe --json` gives the model a machine-readable language description. Structured diagnostics, stable error codes, and fix-its support an edit → check → fix loop.

**3/6**

The compiler and assembler are written in Lume.

A frozen C seed bootstraps them once. Lume then rebuilds Lume, and CI checks a bit-identical stage 2 == stage 3 fixpoint—with no C compiler, external assembler, or linker in the steady state.

**4/6**

For supported QF_LIA contracts, Lume can prove properties or return counterexamples.

Unsupported obligations stay runtime-checked. A standalone verifier independently re-derives proofs instead of trusting the compiler’s verdict.

**5/6**

The goal is not “trust everything AI writes.”

It is the opposite: make AI-authored software easier to constrain, verify, audit, and repair—while humans retain review and approval.

**6/6**

The repository includes the compiler, examples, documentation, native interop demos, and an experimental x86-64 kernel booting in QEMU.

Try it, inspect the claims, and tell me where the design breaks:
https://github.com/OmegaSoftDLL/lume

### LinkedIn

**Text:**

Most programming languages were designed for a human author. Lume explores a different model: AI writes the code, the compiler checks it, and humans review and govern the result.

That means prioritizing structured diagnostics over clever syntax, explicit contracts and effects, machine-readable language description, provenance, and independently verifiable proofs for supported properties.

The compiler and assembler are written in Lume. The bootstrap verifies a bit-identical self-hosting fixpoint, with no C compiler or external assembler/linker in the steady-state toolchain.

Lume is experimental—not a claim that AI-generated software is automatically trustworthy. The goal is to make that software more checkable and auditable.

Watch the demo and explore the project: https://github.com/OmegaSoftDLL/lume

I would especially value feedback from people working on compilers, AI coding agents, formal verification, and developer tools.

### dev.to article

**Title:** I designed a programming language for AI authors and human reviewers

**Suggested tags:** `programming`, `compilers`, `ai`, `opensource`

**Structure and opening:**

Most discussions about AI and programming focus on the model. Lume focuses on the other half of the problem: what should the language and compiler look like when most code is machine-authored?

The article should then show, with real commands and captured output:

1. **The failure mode:** plausible but wrong AI output and the limits of text-only review.
2. **The language loop:** self-description, structured diagnostics, typed holes, repair, and provenance.
3. **The toolchain:** a diagram of the frozen seed and the self-hosting stage 2/stage 3 fixpoint.
4. **The evidence:** one supported contract, one counterexample, one runtime-checked fallback, and independent certificate verification.
5. **The demo:** install and run the smallest complete example.
6. **The limits:** experimental status, QF_LIA scope, `main` versus releases, GPU/WASM/kernel caveats.
7. **The question:** what evidence would readers require before trusting AI-authored components?

End with the repository and a request for technical criticism, not generic praise or stars.

### Mastodon

**Text:**

Lume is an experimental programming language for AI-authored, human-reviewed code.

It has structured diagnostics for repair loops, a self-hosted compiler/assembler with a bit-identical bootstrap fixpoint, and independently verifiable proofs for supported QF_LIA contracts.

No claim that AI output is automatically trustworthy—the point is to make it easier to check.

Source and demo: https://github.com/OmegaSoftDLL/lume

### Portuguese / r/brdev / TabNews adaptation

**Title:** Lume: uma linguagem experimental criada para código escrito por IA e revisado por humanos

**Body:**

Tenho trabalhado no Lume, uma linguagem experimental que parte de uma pergunta: como deveria ser uma linguagem se o autor principal do código fosse uma IA e o humano atuasse como revisor e responsável pelas decisões?

Em vez de priorizar apenas digitar menos, o Lume prioriza verificação e rastreabilidade: diagnósticos estruturados, contratos, efeitos explícitos, proveniência e um fluxo de edição → verificação → correção pensado para agentes de IA.

O compilador e o assembler são escritos em Lume. Uma semente inicial em C, mantida congelada, gera as primeiras ferramentas; depois o próprio Lume reconstrói o toolchain, com uma verificação de que os estágios 2 e 3 são idênticos bit a bit. No fluxo principal não entram compilador C, assembler ou linker externos.

Para contratos dentro do fragmento QF_LIA suportado, o projeto também tem verificação formal e certificados que podem ser conferidos de forma independente. O que não pode ser provado continua com verificação em runtime, sem ser apresentado como “provado”.

O projeto é experimental e aberto a críticas técnicas:
https://github.com/OmegaSoftDLL/lume

Para quem trabalha com compiladores, IA ou verificação: qual seria a maior falha desse modelo “IA escreve, compilador verifica, humano decide”?

Adapt the title and format to each Brazilian community’s rules; do not paste the same text into several communities on the same day.

## Calendar

| Week | Community | Topic | Goal |
|---|---|---|---|
| 1 | r/ProgrammingLanguages | AI-first language introduction | Initial technical feedback |
| 2 | r/Compilers | Self-hosting and bootstrap fixpoint | Compiler-design discussion |
| 3 | r/programming, if rules permit | Designing for AI authors and human reviewers | Broader design debate |
| 4 | r/ProgrammingLanguages | QF_LIA proofs and independent certificates | Verification scrutiny |
| 5 | r/osdev | Lume-written x86-64 kernel in QEMU | Systems feedback |
| 6 | r/programming or r/opensource, if rules permit | Verified sidecars and zero-migration adoption | Interop and adoption feedback |

## Post 1 — AI-first introduction

**Community:** r/ProgrammingLanguages

**Title:** Lume: an AI-first programming language designed for machine-authored, human-reviewed code

**Body:**

I’ve been working on Lume, an experimental language built around a deliberate inversion: the primary code author is an AI model, while humans review, direct, and approve.

That changes the design priorities. Instead of optimizing mainly for fewer keystrokes, Lume optimizes for machine checkability and an unambiguous edit → check → fix loop:

- structured diagnostics with stable codes and fix-its;
- `lume describe --json`, a machine-readable self-description for models that have never seen the language;
- explicit effects, contracts, tests, and provenance at public boundaries;
- typed holes and compiler-as-a-service tools for candidate generation, witnesses, repairs, and impact analysis;
- a canonical formatter and content-addressed AST hashes.

The compiler and assembler are themselves written in Lume. The bootstrap verifies a bit-identical `stage 2 == stage 3` fixpoint, and the steady-state native path uses no C compiler or external assembler/linker. A frozen C seed remains as the reproducibility root.

This is still an experimental project, not a claim that AI output is automatically trustworthy. The bet is that a language should make AI mistakes easier to detect, constrain, and repair—not merely easier to generate.

Repository: https://github.com/OmegaSoftDLL/lume

AI-first design rationale: https://github.com/OmegaSoftDLL/lume/blob/main/docs/08-ai-first.md

For language designers: what is the biggest weakness in this “AI authors, compiler checks, humans govern” model? I’m especially interested in failure modes that better diagnostics alone would not solve.

## Post 2 — Self-hosting and bootstrap

**Community:** r/Compilers

**Title:** A bit-identical self-hosting fixpoint: Lume rebuilds Lume without C in the steady state

**Body:**

I’d like to share the bootstrap architecture of Lume and get feedback from compiler people.

Lume’s compiler (`lumec`) and assembler/ELF writer (`lasm`) are written in Lume. A frozen C seed builds the first tools once; after that, Lume rebuilds the toolchain itself. The bootstrap checks that stage 2 and stage 3 are bit-for-bit identical.

The steady-state pipeline is:

```text
Lume source
  -> Lume-written compiler
  -> x86-64 assembly
  -> Lume-written assembler + ELF writer
  -> native executable
```

No C compiler, external `as`, external `ld`, or libc is used on that steady-state path. The C seed is deliberately frozen with a SHA-256 manifest as the reproducibility root rather than being an expanding second implementation.

The compiler now also uses some of the language’s own features: contracts in compiler passes, algebraic effects at the I/O boundary, and ownership/Perceus-style reuse in hot paths. The CI gates include the self-hosting fixpoint and a zero-C steady-state check.

Technical overview: https://github.com/OmegaSoftDLL/lume#how-lume-is-built-no-third-language-in-the-loop

Current implementation state: https://github.com/OmegaSoftDLL/lume/blob/main/docs/PROJECT_STATE.md

For people who have built self-hosting compilers: what additional bootstrap or trusting-trust checks would you consider essential beyond a bit-identical stage 2/stage 3 comparison?

## Post 3 — AI-first language design discussion

**Community:** r/programming, only if current rules allow project posts

**Title:** What changes when a programming language treats AI as the primary author?

**Body:**

Most languages assume a human writes the code and a machine runs it. Lume experiments with the opposite authoring model: an AI writes, the compiler checks, and a human reviews and governs.

The interesting part is not “AI can generate another syntax.” It is how the language changes when model failure modes drive the design:

- Checkability over brevity: explicit contracts and effects give the compiler more intent to verify.
- One canonical form: fewer stylistic choices and more predictable semantic diffs.
- Diagnostics as an API: stable codes, structured JSON, expected/actual information, and fix-its support mechanical repair loops.
- Self-description as a language feature: `lume describe --json` teaches a model the grammar and workflow instead of assuming Lume appeared in training data.
- Provenance: unverified values cannot silently flow into trusted or effectful sinks without a discharge step.

Humans are not removed; their role shifts from typist to reviewer and decision-maker. That still leaves hard problems: a precise specification can encode the wrong intent, and a proof cannot replace product judgment.

The project is experimental and open source: https://github.com/OmegaSoftDLL/lume

Design document: https://github.com/OmegaSoftDLL/lume/blob/main/docs/08-ai-first.md

Would you accept more verbosity and explicit contracts in AI-authored code if it made automated review substantially more reliable? Where would you draw that trade-off?

## Post 4 — Proofs and certificates

**Community:** r/ProgrammingLanguages

**Title:** Independent proof certificates for AI-generated code—QF_LIA, not “proof by sampling”

**Body:**

One of Lume’s goals is to make AI-generated code carry evidence that another tool can independently check.

For supported linear integer arithmetic contracts, Lume uses a QF_LIA decision procedure based on Fourier–Motzkin elimination. An obligation decided by that procedure can be marked `proven`; a false obligation can produce a concrete counterexample. Obligations outside the supported fragment remain `runtime_checked` rather than being silently promoted to proofs.

The standalone certificate verifier has its own parser and QF_LIA solver. It re-derives the proof obligation and checks SHA-256 integrity instead of trusting a verdict emitted by the main compiler.

The important limitations are explicit:

- This is not general program correctness.
- QF_LIA covers a specific fragment; nonlinear and unsupported properties can remain runtime-checked.
- A verified contract only establishes the stated property, not that the specification captured every human requirement.
- AI authorship still needs human review and governance.

The same machinery supports compiler-oracle queries such as finding a contract-breaking witness, proposing a repair, and reporting affected proofs after a change.

Project: https://github.com/OmegaSoftDLL/lume

Current trust-layer details: https://github.com/OmegaSoftDLL/lume/blob/main/docs/PROJECT_STATE.md

For verification practitioners: what would you want an independent certificate to contain before considering it useful in code review or package auditing?

## Post 5 — Systems and kernel work

**Community:** r/osdev

**Title:** Booting a Lume-written x86-64 kernel in QEMU

**Body:**

I’ve been experimenting with using Lume for systems programming, and the current `main` branch has a small freestanding x86-64 kernel that boots in QEMU.

The implemented path includes an MBR boot image, four-level paging and long mode, a hardware IDT, page-fault and timer interrupt handling, COM1 serial output, APIC-based SMP bring-up, and a two-task context switch. The language side includes freestanding code generation, volatile MMIO, interrupt annotations, structural cycle-budget checks, and linear capabilities for resources such as pages, ports, and IRQs.

This is not a general-purpose operating system yet. Filesystems, networking, and a fuller userland remain build-out work. The current value is testing whether the language’s ownership, capability, and verification ideas remain useful when the runtime comforts disappear.

Kernel example: https://github.com/OmegaSoftDLL/lume/tree/main/examples/apps/lume_os

Project: https://github.com/OmegaSoftDLL/lume

For OS developers: which mechanism would you stress-test first in a small capability-oriented kernel—page-capability safety, interrupt handling, SMP scheduling, or IPC?

## Post 6 — Verified sidecars and adoption

**Community:** r/programming or r/opensource, only where current rules permit

**Title:** Adopting a new language without migrating: verified Lume sidecars for C, Python, and Node

**Body:**

A new language has an adoption problem: almost nobody wants to rewrite a working codebase. Lume’s current interop experiment instead asks, “Can you move only the critical 5% into a checked core?”

The repository includes a sidecar example where a small payment-related core is written in Lume and called from C, Python, and Node hosts. Lume supports reverse C-ABI exports and can emit a proof certificate for supported contracts, so a host can use the native function while tooling independently verifies the evidence.

The intended workflow is:

1. Keep the existing application.
2. Express a small, high-value invariant in Lume—for example, a settlement or state-transition rule.
3. Verify the supported contract and export the native interface.
4. Audit capabilities, lockfile integrity, and proof status when dependencies change.

This is experimental, and the proof scope is limited to the properties and fragments the verifier actually supports. The in-language `std.wasm` sandbox is currently a reference model, not a claim of real WASM runtime isolation.

Sidecar example: https://github.com/OmegaSoftDLL/lume/tree/main/examples/interop/sidecar

Adoption rationale: https://github.com/OmegaSoftDLL/lume/blob/main/docs/22-adoption.md

Would a narrowly scoped, verifiable native component be a realistic way to introduce a new language in your stack, or does the extra operational complexity outweigh the benefit?

## Response bank

Use these as starting points, not scripted replies. Answer the commenter’s exact technical point first.

### “There is C in the repository, so ‘no C’ is misleading.”

You’re right that the repository contains C. The precise claim is that C is absent from the steady-state toolchain after the frozen seed mints the first Lume-written compiler and assembler. The seed remains as the reproducibility root and is covered by a freeze manifest. I’ll use that longer formulation where the shorter one could mislead.

### “A proof does not mean the program is correct.”

Agreed. A proof establishes a stated property within a supported formal fragment; it does not prove that the specification is complete or that the human asked for the right thing. That is why Lume keeps human review, tests, counterexamples, and runtime checks alongside proofs.

### “This is just AI-generated hype.”

AI authorship is a reason for more scrutiny, not less. The useful way to evaluate the project is to inspect the executable gates: the self-hosting fixpoint, negative tests, counterexamples, independent certificate re-derivation, and explicit runtime-checked fallbacks. If any claim exceeds what runs, that should be corrected.

### “Why not use Rust?”

Rust is a strong choice for many systems, and Lume is not claiming to be a drop-in replacement. Lume’s experiment is specifically the AI-authoring loop: structured compiler APIs, provenance, typed holes, self-description, proof-oriented workflows, and human governance. Interop is intended to let a small Lume core coexist with existing stacks rather than require a rewrite.

### “Is it production-ready?”

No. It is an experimental language and toolchain under active development. The repository distinguishes shipped functionality, models, and planned work; the moving `main` branch should also not be confused with the latest tagged release.

### “Does it run GPU kernels on physical GPUs?”

Not yet. The current PTX/SPIR-V path performs SSA lowering and executes on instruction-level VM emulators with cross-backend checks. Physical GPU driver launch is planned.

### “Is the WASM sandbox real isolation?”

No. `std.wasm` is currently an in-language reference model with capability, fuel, and bounds checks plus compile-time capability enforcement. It should not be described as a real WASM runtime security boundary.

### “Is Lume OS a complete operating system?”

No. It is an experimental kernel that boots in QEMU with several real low-level mechanisms. Filesystems, networking, and a fuller userland are still future work.

## Publishing checklist

Before each post:

- [ ] Confirm account standing, subreddit eligibility, and any account-age/karma requirement.
- [ ] Read the community’s current rules and self-promotion policy.
- [ ] Verify that every feature mentioned still matches `main` and the linked documentation.
- [ ] If mentioning a release, inspect that tag rather than copying claims from `main`.
- [ ] Use the appropriate flair if required.
- [ ] Check that links work while logged out.
- [ ] Be available to answer comments for the first few hours.
- [ ] Record useful criticism and update later drafts instead of repeating a rejected pitch.

## What to measure

Prioritize evidence of useful discussion over vanity metrics:

- Technical questions and substantive criticisms per post.
- Documentation clicks and unique visitors to the repository.
- Issues or discussions opened by new contributors.
- Attempts to install, run an example, or verify a certificate.
- Returning commenters and contributors across the six-week campaign.

Do not optimize the next draft solely for upvotes or stars. The campaign succeeds if it brings in informed scrutiny and reproducible external feedback.
