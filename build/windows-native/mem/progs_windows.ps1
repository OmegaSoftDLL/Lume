# `lume run` on every program of a list (native Windows tree): stdout, stderr and exit status per program.
# Usage: progs_windows.ps1 [-List <file>] [-Out <dir>]   (defaults: progs_all.txt, pr_w)
param([string]$List = 'progs_all.txt', [string]$Out = 'pr_w')
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
Set-Location $root
$outDir = Join-Path $here $Out
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir -Confirm:$false }
New-Item -ItemType Directory -Force $outDir | Out-Null
$rel = "build\windows-native\mem\$Out"
$lines = @()
foreach ($f in [System.IO.File]::ReadAllLines((Join-Path $here $List))) {
    if ($f.Length -eq 0) { continue }
    $n = ($f -replace '/', '_') -replace '\.src$', ''
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c build\windows-native\inst\bin\lume.exe run $f > $rel\$n.out 2> $rel\$n.err < NUL" -NoNewWindow -PassThru
    if (-not $p.WaitForExit(300000)) {
        cmd /c "taskkill /PID $($p.Id) /T /F > NUL 2>&1"
        $lines += "$n 124"
    } else { $lines += "$n $($p.ExitCode)" }
    [System.IO.File]::WriteAllText((Join-Path $outDir 'summary.txt'), ($lines -join "`n") + "`n")
}
"programs: $($lines.Count)"
