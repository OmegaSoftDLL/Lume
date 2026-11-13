# Every program of a list (native Windows tree): stdout, stderr and exit status per program.
# Usage: progs_windows.ps1 [-List <file>] [-Out <dir>]   (defaults: progs_all.txt, pr_w)
# Most programs are `lume run`; progs_modes.txt names the others and how they are exercised (as progs_linux.sh):
#   kernel -> `lume build <f> -o <name>.kernel`; server -> still serving after 5 s = 0; gate -> built, then run with
#   "@root" and "@bin" on stdin; via <gate> -> the status of that gate run. progs_verdict.src gives pass/fail.
param([string]$List = 'progs_all.txt', [string]$Out = 'pr_w')
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
Set-Location $root
$outDir = Join-Path $here $Out
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir -Confirm:$false }
New-Item -ItemType Directory -Force $outDir | Out-Null
# a fresh, empty home per run: no test may read or write the real ~/.lume, ~/.lume_sovereign_memory or ProgramData vault
$sandboxHome = $outDir + '.home'; if (Test-Path $sandboxHome) { Remove-Item -Recurse -Force $sandboxHome -Confirm:$false }
$sandboxWin = Join-Path $sandboxHome 'win'; $sandboxVault = Join-Path $sandboxHome 'vault'
New-Item -ItemType Directory -Force $sandboxWin, $sandboxVault | Out-Null
$env:HOME = $sandboxHome; $env:USERPROFILE = $sandboxHome; $env:LUME_WIN_HOME = $sandboxWin; $env:LUME_SYSTEM_VAULT = $sandboxVault
$rel = "build\windows-native\mem\$Out"
$lume = 'build\windows-native\inst\bin\lume.exe'
$binDir = Join-Path $root 'build\windows-native\inst\bin'
function PosixOf([string]$p) { '/' + $p.Substring(0, 1).ToLower() + ($p.Substring(2) -replace '\\', '/') }
$modes = @{}
foreach ($m in [System.IO.File]::ReadAllLines((Join-Path $here 'progs_modes.txt'))) {
    $parts = $m -split ' '
    if ($parts.Length -ge 2) { $modes[$parts[0]] = $parts[1..($parts.Length - 1)] }
}
# one command through cmd.exe with a time limit (ms): its exit status, 124 when it had to be stopped
function Invoke-Limited([string]$cmdline, [int]$ms) {
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $cmdline" -NoNewWindow -PassThru
    $null = $p.Handle   # cache the handle, or ExitCode is lost after WaitForExit(timeout)
    if (-not $p.WaitForExit($ms)) { cmd /c "taskkill /PID $($p.Id) /T /F > NUL 2>&1"; return 124 }
    return $p.ExitCode
}
function Invoke-Gate([string]$gate, [string]$n) {
    $b = Invoke-Limited "$lume build $gate -o $rel\$n.gate.exe > $rel\$n.gate.build 2>&1 < NUL" 1800000
    if ($b -ne 0) { return 3 }
    [System.IO.File]::WriteAllText((Join-Path $outDir "$n.in"), "@root $(PosixOf $root)`n@bin $(PosixOf $binDir)`n")
    return (Invoke-Limited "$rel\$n.gate.exe < $rel\$n.in > $rel\$n.out 2> $rel\$n.err" 3600000)
}
$lines = @()
foreach ($f in [System.IO.File]::ReadAllLines((Join-Path $here $List))) {
    if ($f.Length -eq 0) { continue }
    $n = ($f -replace '/', '_') -replace '\.src$', ''
    $mode = if ($modes.ContainsKey($f)) { $modes[$f][0] } else { '' }
    if ($mode -eq 'kernel') {
        $st = Invoke-Limited "$lume build $f -o $rel\$n.kernel > $rel\$n.out 2> $rel\$n.err < NUL" 300000
        Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $outDir "$n.kernel")
    } elseif ($mode -eq 'server') {
        $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $lume run $f > $rel\$n.out 2> $rel\$n.err < NUL" -NoNewWindow -PassThru
        $null = $p.Handle
        if (-not $p.WaitForExit(5000)) { cmd /c "taskkill /PID $($p.Id) /T /F > NUL 2>&1"; $st = 0 } else { $st = $p.ExitCode }
    } elseif ($mode -eq 'gate') {
        $st = Invoke-Gate $f $n
    } elseif ($mode -eq 'via') {
        $st = Invoke-Gate $modes[$f][1] $n
    } else {
        $st = Invoke-Limited "$lume run $f > $rel\$n.out 2> $rel\$n.err < NUL" 300000
    }
    $lines += "$n $st"
    [System.IO.File]::WriteAllText((Join-Path $outDir 'summary.txt'), ($lines -join "`n") + "`n")
}
"programs: $($lines.Count)"
