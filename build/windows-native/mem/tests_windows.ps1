# lume test on each file of tests_list.txt with the native Windows tool tree; results in mem\lt_w.
$root = (Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\..\..')).Path
Set-Location $root
$out = Join-Path $root 'build\windows-native\mem\lt_w'
New-Item -ItemType Directory -Force $out | Out-Null
$lines = @()
foreach ($f in [System.IO.File]::ReadAllLines((Join-Path $root 'build\windows-native\mem\tests_list.txt'))) {
    if ($f.Length -eq 0) { continue }
    $n = [IO.Path]::GetFileNameWithoutExtension($f)
    cmd /c "build\windows-native\inst\bin\lume.exe test $f > build\windows-native\mem\lt_w\$n.out 2>&1"
    $lines += "$n $LASTEXITCODE"
}
[System.IO.File]::WriteAllText((Join-Path $out 'summary.txt'), ($lines -join "`n") + "`n")
$lines
