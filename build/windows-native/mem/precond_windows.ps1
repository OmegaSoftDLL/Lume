# The four test files that need what bootstrap/lume0/tests/run.sh sets up, on the native Windows tree: run from
# bootstrap/lume0 (as run.sh does), with the probes (os_run_probe, os_run_slow_probe, os_run_input_probe, process_probe) built
# and their *_path files written. Output per file in mem\<Out>, same names as tests_windows.ps1.
# Usage: precond_windows.ps1 [-Out <dir>]   (default pc_w)
param([string]$Out = 'pc_w')
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
$outDir = Join-Path $here $Out
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir -Confirm:$false }
New-Item -ItemType Directory -Force $outDir | Out-Null
# a fresh, empty home: no test may read or write the real ~/.lume, ~/.lume_sovereign_memory or ProgramData vault
$sandboxHome = $outDir + '.home'; if (Test-Path $sandboxHome) { Remove-Item -Recurse -Force $sandboxHome -Confirm:$false }
$sandboxWin = Join-Path $sandboxHome 'win'; $sandboxVault = Join-Path $sandboxHome 'vault'
New-Item -ItemType Directory -Force $sandboxWin, $sandboxVault | Out-Null
$env:HOME = $sandboxHome; $env:USERPROFILE = $sandboxHome; $env:LUME_WIN_HOME = $sandboxWin; $env:LUME_SYSTEM_VAULT = $sandboxVault
$B = Join-Path $root 'build\windows-native\inst\bin'
$probeDir = Join-Path $here 'probes_w'
New-Item -ItemType Directory -Force $probeDir | Out-Null
$tests = Join-Path $root 'bootstrap\lume0'
Set-Location $tests
function PosixOf([string]$p) { '/' + $p.Substring(0, 1).ToLower() + ($p.Substring(2) -replace '\\', '/') }
foreach ($name in 'os_run_probe', 'os_run_slow_probe', 'os_run_input_probe', 'process_probe') {
    # an existing probe is kept: a rebuilt file is a new file for the antivirus, which holds it again
    if (-not (Test-Path (Join-Path $probeDir "$name.exe"))) {
        cmd /c "`"$B\lumec.exe`" --win64 < `"$root\compiler\stage1\$name.src`" > `"$probeDir\$name.s`" && `"$B\lasm.exe`" --pe `"$probeDir\$name.s`" > `"$probeDir\$name.exe`""
    }
    [System.IO.File]::WriteAllText((Join-Path $tests "${name}_path"), (PosixOf (Join-Path $probeDir "$name.exe")))
}
[System.IO.File]::WriteAllText((Join-Path $tests 'std_process_slow_probe_path'), (PosixOf (Join-Path $probeDir 'os_run_slow_probe.exe')))
$lines = @()
foreach ($t in 'fs_path_exists_ok', 'fs_read_byte_ok', 'os_run_ok', 'process_ok') {
    $n = "compiler_stage1_$t"
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c ..\..\build\windows-native\inst\bin\lume.exe test ../../compiler/stage1/$t.src > ..\..\build\windows-native\mem\$Out\$n.out 2>&1 < NUL" -NoNewWindow -PassThru -WorkingDirectory $tests
    $null = $p.Handle
    if (-not $p.WaitForExit(1200000)) { cmd /c "taskkill /PID $($p.Id) /T /F > NUL 2>&1"; $lines += "$n TIMEOUT" } else { $lines += "$n $($p.ExitCode)" }
}
[System.IO.File]::WriteAllText((Join-Path $outDir 'summary.txt'), ($lines -join "`n") + "`n")
foreach ($f in 'os_run_probe_path', 'os_run_slow_probe_path', 'os_run_input_probe_path', 'process_probe_path', 'std_process_slow_probe_path',
               'os_run_capture_stdout', 'os_run_capture_stderr', 'os_run_timeout_stdout', 'os_run_timeout_stderr', 'os_run_input_data',
               'os_run_input_stdout', 'os_run_input_stderr', 'os_run_input_missing_stdout', 'os_run_input_missing_stderr',
               'std_process_stdin_probe', 'std_process_stdout_probe', 'std_process_stderr_probe', 'fs_read_byte_probe') {
    Remove-Item (Join-Path $tests $f) -ErrorAction SilentlyContinue
}
$lines
