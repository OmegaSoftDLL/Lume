# os_run_ok.src with the probes run.sh builds, on the native Windows tree (lumec --win64 + lasm --pe).
$root = (Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\..\..')).Path
Set-Location $root
$P = Join-Path $root 'build\windows-native\mem\probes_w'
New-Item -ItemType Directory -Force $P | Out-Null
$B = 'build\windows-native\inst\bin'
foreach ($p in 'os_run_probe', 'os_run_slow_probe', 'os_run_input_probe') {
    cmd /c "$B\lumec.exe --win64 < compiler\stage1\$p.src > $P\$p.s && $B\lasm.exe --pe $P\$p.s > $P\$p.exe"
    $posix = '/' + $root.Substring(0, 1).ToLower() + ($root.Substring(2) -replace '\\', '/') + "/build/windows-native/mem/probes_w/$p"
    [System.IO.File]::WriteAllText((Join-Path $root "${p}_path"), $posix)
}
cmd /c "$B\lume.exe test compiler/stage1/os_run_ok.src 2>&1"
"exit=$LASTEXITCODE"
foreach ($f in 'os_run_probe_path', 'os_run_slow_probe_path', 'os_run_input_probe_path', 'os_run_capture_stdout', 'os_run_capture_stderr', 'os_run_timeout_stdout', 'os_run_timeout_stderr', 'os_run_input_data', 'os_run_input_stdout', 'os_run_input_stderr', 'os_run_input_missing_stdout', 'os_run_input_missing_stderr') {
    Remove-Item (Join-Path $root $f) -ErrorAction SilentlyContinue
}
