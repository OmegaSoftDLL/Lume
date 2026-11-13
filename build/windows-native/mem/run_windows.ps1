# Run the memory battery on Windows: every program plain, then every case of cases.txt. Results in mem\res_windows.
# Output is captured through cmd.exe redirection so the bytes are exactly what the program wrote.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$R = Join-Path $here 'res_windows'
if (Test-Path $R) { Remove-Item -Recurse -Force $R -Confirm:$false }
New-Item -ItemType Directory -Force $R | Out-Null
$bin = Join-Path $here 'bin'
$names = 'LUME_GC_STRESS', 'LUME_ARENA_COLD', 'LUME_HEAP_CAP', 'LUME_GC'
function One($id, $exe, $envs, $argv) {
    foreach ($n in $names) { Remove-Item "Env:$n" -ErrorAction SilentlyContinue }
    if ($envs -ne '-') { foreach ($kv in $envs.Split(' ')) { $p = $kv.Split('=', 2); Set-Item "Env:$($p[0])" $p[1] } }
    $a = if ($argv -eq '-') { '' } else { $argv }
    Push-Location $R
    cmd /c "`"$bin\$exe`" $a > $id.out 2> $id.err"
    $code = $LASTEXITCODE
    Pop-Location
    [System.IO.File]::WriteAllText((Join-Path $R "$id.code"), "$code`n")
    foreach ($n in $names) { Remove-Item "Env:$n" -ErrorAction SilentlyContinue }
}
Get-ChildItem (Join-Path $bin '*.exe') | ForEach-Object { One ("plain_" + $_.BaseName) $_.Name '-' '-' }
foreach ($l in [System.IO.File]::ReadAllLines((Join-Path $here 'cases.txt'))) {
    if ($l.StartsWith('#') -or $l.Length -eq 0) { continue }
    $f = $l.Split('|')
    One $f[0] ($f[1] + '.exe') $f[2] $f[3]
}
$lines = Get-ChildItem (Join-Path $R '*.code') | ForEach-Object { $_.BaseName + ' ' + ([System.IO.File]::ReadAllText($_.FullName).Trim()) }
[System.IO.File]::WriteAllText((Join-Path $R 'summary.txt'), (($lines | Sort-Object) -join "`n") + "`n")
"summary: $($lines.Count) results"
