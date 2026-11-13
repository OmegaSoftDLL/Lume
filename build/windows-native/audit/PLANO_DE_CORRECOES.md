# Plano de correções — porte Windows e achados das auditorias (2026-11-13)

Fontes: `domains_122_map.md`, `processor_memory_audit.md`, `dossie_parte_0_II.md`, `dossie_parte_IV.md`,
`dossie_parte_V.md`, `dossie_parte_VI.md`, `catalogo_parte_IX.md`, `catalogo_partes_X_XI.md` (todos nesta pasta),
mais a verificação de memória (docs/42 §6.1).

Legenda: ✅ feito e testado nos dois sistemas · 🔧 feito, falta teste cruzado · ⏳ pendente · 📝 só documentação.

## 1. Camada Win64 (`build/windows-native/win64_layer.s` → `rt_win64_layer`)

| Item | Estado |
| --- | --- |
| Tabela de descritores estilo Linux (0-2 padrão, menor livre ≥ 3, EMFILE) | ✅ |
| Console em modo cozido: `\r\n` → `\n` na leitura | ✅ |
| `MAP_NORESERVE` com commit preguiçoso (VEH + antes de read/write) | ✅ |
| `PROT_READ` / `PROT_READ|PROT_EXEC` sem virar gravável | ✅ |
| `madvise` sem recommit → mensagem de falta de memória + 12 | ✅ |
| VEH só trata AV do próprio código / reservas; DLLs seguem seu `__try` | ✅ |
| Sonda de pilha para frames ≥ 4 KiB (`lumec --win64`) | ✅ |
| `maxrss`, `exit & 255`, `getrlimit` 4 GiB, `rename` + EXDEV/EMFILE | ✅ |
| `rmdir` (84); `unlink` de arquivo somente leitura | 🔧 |
| `chmod`: bit de escrita do dono ↔ READONLY | 🔧 |
| Caminho terminado em `/` ou `/.` exige diretório (ENOTDIR) | ✅ |
| `execve` repassa o envp (bloco UTF-16, `CREATE_UNICODE_ENVIRONMENT`) | ✅ |
| `uname` (63): Windows_NT, versão do KUSER_SHARED_DATA, x86_64 | 🔧 |
| `clock_gettime` CPU de processo/thread (2/3) | 🔧 |
| Sockets 41-45/48-50/54 (Winsock do sistema, carregado sob demanda; socket na tabela de fds) | ✅ |
| epoll 232/233/291 → IOCP / `WSAPoll` | ⏳ |
| io_uring 425-427 → IoRing (Windows 11) | ⏳ |
| `MAP_SHARED` / `os_shm_map` → `CreateFileMapping` | ⏳ |
| `os_fork` sem exec: fork real (cópia da imagem, regiões, pilha e handles; retomada no ponto do fork) | ✅ (20/20) |
| `lasm`: `call *%reg` / `jmp *%reg` (família `indirect` no lasm_gate) | 🔧 |
| `kill` no próprio processo com sinal exato | 🔧 |
| Limite de pilha por filho (soak: `ulimit -s`) | ⏳ |
| DWARF → CodeView/PDB | ⏳ |
| FFI C com ABI Win64 | ⏳ |

## 2. Runtime e builtins novos (iguais nos dois sistemas)

| Builtin | Estado |
| --- | --- |
| `os_platform`, `fs_chdir`, `fs_copy`, `fs_rename`, `fs_make_executable` | ✅ |
| `os_getenv` (era só nome reservado) | ✅ |
| `os_setenv`, `os_unsetenv` (valem para os filhos) | ✅ |
| `fs_chmod(path, mode)` | ✅ |
| `fs_remove` também remove diretório vazio | 🔧 |
| `os_unix_time`, `os_uname_field` | 🔧 |
| `os_spawn_capture` (processo sem esperar; `os_waitpid_status` espera) | 🔧 |

## 3. `hostio.src` (Lume) — sem processos externos para operações de arquivo

✅ caminhos do host (`hio_home`, `hio_lume_home`, `hio_data_dir`, `hio_system_vault`, `hio_win_system32`,
`hio_win_home`), `mkdir -p`, `rm -rf`, `cp -R`, `mv`, `chmod`, `ls`, `pwd`, `printenv`, `test`, `env`, 🔧 `date`,
`uname`, busca no PATH (`hio_which`/`hio_resolve`), `hio_tool_exists`, helpers de build do host.
Roteados por `hio_osrun*`: 143 chamadas diretas reescritas + 30 arquivos com todos os `os_run*` passando pelo
despachante.

## 4. Defeitos corrigidos no código

| Defeito | Onde | Estado |
| --- | --- | --- |
| `bios-core` dizia `ntoskrnl_mz_verified=1` sem o arquivo | lsentience | ✅ |
| `file-indexer` inventava formato PE/ELF sem o arquivo | lsentience | ✅ |
| `machine_arch_code` 62 fixo para qualquer não-ELF | lume_reversa_engine | ✅ |
| `ld_sentience_entry` com arquivo padrão deslocado (egm/ncm/opentpu/continuum) | lume_driver | ✅ |
| Caminhos fixos `/root`, `/var/lib`, `/mnt/c/Users/<nome>` | lsentience, motores, driver, lqualify, driver_gate | ✅ |
| Cache do driver ignorava o compilador no Windows (`ld_tool_id` sem `.exe`) | lume_driver | ✅ |
| `ld_w12_native` gerava PE com `syscall` Linux (sem `--win64`) | lume_driver | ✅ |
| `w12_find_lumec` sem `.exe` ([T0903]) | ltarget | ✅ |
| `pc_find_lcaas` sem `.exe` ([PC0003]) | lproof_cache | ✅ |
| Testes serializados com `/bin/sh` + `/usr/bin/flock` | lume_driver | 🔧 (lock por diretório) |
| Canal A do envelope gerava/executava `.elf` no Windows | lsafety_envelope | 🔧 |
| `lconcurrency` despachava workers por script `sh` | lconcurrency, concurrency_gate | 🔧 |
| Reconstrução protegida via `/bin/sh -c "... && cp ..."` | lsentience | 🔧 |

## 5. Pendente — ferramentas e gates

| Item | Dependência hoje |
| --- | --- |
| Gates que executam programa nativo (realtime, tv, tv_rt, ownership, prover_fuzz, soak, safety_envelope, runtime_sync, crypto_tls, cert_source) | ELF fixo; trocar por `hio_cflags`/`hio_aflags` onde executa |
| `ltv`/`lmcdc --exec`, `lstack` sobre `.s` do Windows | ELF; modelar `__win_syscall` |
| `lsafety_envelope` modo monitor (`/bin/sh -c ulimit; timeout`) | sh |
| `ltv` solver com `ulimit -s` via sh | sh |
| Gates com `sh` (claude_audit, multi_arch, safetensors, safety_envelope, smt_cert, soak) | sh |
| Oráculos externos (z3, cvc5, qemu, clang/cc, GNU as/objcopy/objdump, readelf/nm/addr2line, python3) | resolvidos pelo PATH; sem eles o gate não roda em nenhum host |
| `web-research` (curl), `economy`/docs_ci/linguist (git), `reverse-engineer` (7z) | programas externos; trocar por Lume (HTTP/TLS exige sockets) |
| `lume_legacy.sh` (pkg ~publish/~audit, superfícies `.lume`, `.wasm`, `fmt` fora de `.src`) | POSIX sh |
| Semente Stage-0 (C), DDC, `make test`/`asan` | cc/clang |
| `lume.exe` nativo resolver `use` fora do diretório do arquivo | driver |
| `ld_root` no Windows aponta para a árvore de instalação, não para o repositório | driver |

## 6. Afirmações falsas dos documentos (📝 corrigir nos docs/README, não no código)

Ver os relatórios: Farkas/Horner/Octógonos não estão no provador; `mem_crc64` é FNV-1a; "HMAC" e "carteiras HD"
do motor blockchain não seguem RFC 2104/BIP32; TLS 1.3 do `std.net` é modelo; Karatsuba e Craig ausentes; lasm
sem vários AVX2 citados e sem A20/CHS; APK/IPA não instaláveis; UEFI importa KERNEL32; capstones com obrigações só
`runtime_checked`; contagens (diagnósticos 121, leis 266, funções 18.857) de um retrato intermediário; 87.224
falhas sem respaldo.
