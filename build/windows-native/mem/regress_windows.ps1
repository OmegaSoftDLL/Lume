# Full Windows side of the regression: memory battery, test list, os_run_ok with probes, net.src.
# Output: mem\regress_w.log (one summary line per part).
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
$log = Join-Path $here 'regress_w.log'
Set-Content $log "regress_windows $(Get-Date -Format s)"
& (Join-Path $here 'run_windows.ps1') | Add-Content $log
& (Join-Path $here 'tests_windows.ps1') | Add-Content $log
Add-Content $log '--- os_run_ok with probes'
& (Join-Path $here 'osrun_windows.ps1') | Select-Object -Last 3 | Add-Content $log
Add-Content $log '--- net.src'
Set-Location $root
cmd /c "build\windows-native\inst\bin\lume.exe test compiler/stage1/net.src > build\windows-native\mem\net_w.out 2>&1"
Add-Content $log "net exit=$LASTEXITCODE"
Get-Content (Join-Path $here 'net_w.out') -Tail 3 | Add-Content $log
Add-Content $log 'END'
