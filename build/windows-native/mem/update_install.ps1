# Update the installed Windows toolchain (C:\Lume by default) from the Windows tree build/windows-native/inst/bin,
# with the native installer itself. Run after every rebuild of the tree that closes a tested step.
# Usage: update_install.ps1 [-Prefix C:\Lume]
param([string]$Prefix = 'C:\Lume')
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $here '..\..\..')).Path
function PosixOf([string]$p) { '/' + $p.Substring(0, 1).ToLower() + ($p.Substring(2) -replace '\\', '/') }
$inst = Join-Path $root 'build\windows-native\inst\bin'
& (Join-Path $inst 'native_installer.exe') --prefix (PosixOf $Prefix) --from-local (PosixOf $root) --from-dir (PosixOf $inst)
if ($LASTEXITCODE -ne 0) { "update failed: exit $LASTEXITCODE"; exit $LASTEXITCODE }
& (Join-Path $Prefix 'bin\lume.exe') --version
"installed from $inst at $(Get-Date -Format 'yyyy-MM-dd HH:mm') (git $(git -C $root rev-parse --short HEAD))"
