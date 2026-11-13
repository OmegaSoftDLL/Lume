# lume test on each file of a list with the native Windows tool tree.
# Usage: tests_windows.ps1 [-List <file>] [-Out <dir>]   (defaults: tests_list.txt, lt_w)
param([string]$List = 'tests_list.txt', [string]$Out = 'lt_w')
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
$lines = @()
foreach ($f in [System.IO.File]::ReadAllLines((Join-Path $here $List))) {
    if ($f.Length -eq 0) { continue }
    $n = ($f -replace '/', '_') -replace '\.(src|lume)$', ''
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c build\windows-native\inst\bin\lume.exe test $f > $rel\$n.out 2>&1 < NUL" -NoNewWindow -PassThru
    $null = $p.Handle   # cache the handle, or ExitCode is lost after WaitForExit(timeout)
    if (-not $p.WaitForExit(1200000)) {
        # a test that hangs: stop its whole process tree, record it
        cmd /c "taskkill /PID $($p.Id) /T /F > NUL 2>&1"
        $lines += "$n TIMEOUT"
    } else { $lines += "$n $($p.ExitCode)" }
    [System.IO.File]::WriteAllText((Join-Path $outDir 'summary.txt'), ($lines -join "`n") + "`n")
}
"files: $($lines.Count), failing: $(($lines | Where-Object { $_ -notmatch ' 0$' }).Count)"
