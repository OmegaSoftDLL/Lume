# Every gate of gates_all.txt with the native Windows tree: built with `lume build`, then run with "@root <root>" and
# "@bin <tool dir>" on stdin, as CI does. Usage: gates_windows.ps1 [-List <file>] [-Out <dir>] [-Tree <inst dir>]
param([string]$List = 'gates_all.txt', [string]$Out = 'ga_w', [string]$Tree = 'inst')
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
Set-Location $root
$outDir = Join-Path $here $Out
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir -Confirm:$false }
New-Item -ItemType Directory -Force (Join-Path $outDir 'bin') | Out-Null
# a fresh, empty home: no gate may read or write the real ~/.lume, ~/.lume_sovereign_memory or ProgramData vault
$sandboxHome = $outDir + '.home'; if (Test-Path $sandboxHome) { Remove-Item -Recurse -Force $sandboxHome -Confirm:$false }
$sandboxWin = Join-Path $sandboxHome 'win'; $sandboxVault = Join-Path $sandboxHome 'vault'
New-Item -ItemType Directory -Force $sandboxWin, $sandboxVault | Out-Null
$env:HOME = $sandboxHome; $env:USERPROFILE = $sandboxHome; $env:LUME_WIN_HOME = $sandboxWin; $env:LUME_SYSTEM_VAULT = $sandboxVault
# the gates find the tools through LUME_BIN_DIR (hio_bin_dir), as run.sh gives them on Linux
$env:LUME_BIN_DIR = '/' + $root.Substring(0, 1).ToLower() + ($root.Substring(2) -replace '\\', '/') + '/build/windows-native/inst/bin'
function PosixOf([string]$p) { '/' + $p.Substring(0, 1).ToLower() + ($p.Substring(2) -replace '\\', '/') }
$rel = "build\windows-native\mem\$Out"
$bin = "build\windows-native\$Tree\bin"
$lines = @()
foreach ($f in [System.IO.File]::ReadAllLines((Join-Path $here $List))) {
    if ($f.Length -eq 0) { continue }
    $n = ($f -replace '/', '_') -replace '\.src$', ''
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $bin\lume.exe build $f -o $rel\bin\$n.exe > $rel\$n.build 2>&1 < NUL" -NoNewWindow -PassThru
    $null = $p.Handle
    if (-not $p.WaitForExit(1800000)) { cmd /c "taskkill /PID $($p.Id) /T /F > NUL 2>&1"; $lines += "$n BUILD-TIMEOUT"; continue }
    if ($p.ExitCode -ne 0) { $lines += "$n BUILD-FAIL"; [System.IO.File]::WriteAllText((Join-Path $outDir 'summary.txt'), ($lines -join "`n") + "`n"); continue }
    [System.IO.File]::WriteAllText((Join-Path $outDir "$n.in"), "@root $(PosixOf $root)`n@bin $(PosixOf (Join-Path $root $bin))`n")
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $rel\bin\$n.exe < $rel\$n.in > $rel\$n.out 2> $rel\$n.err" -NoNewWindow -PassThru
    $null = $p.Handle
    if (-not $p.WaitForExit(3600000)) { cmd /c "taskkill /PID $($p.Id) /T /F > NUL 2>&1"; $lines += "$n 124" } else { $lines += "$n $($p.ExitCode)" }
    [System.IO.File]::WriteAllText((Join-Path $outDir 'summary.txt'), ($lines -join "`n") + "`n")
}
"gates: $($lines.Count), not 0: $(($lines | Where-Object { $_ -notmatch ' 0$' }).Count)"
