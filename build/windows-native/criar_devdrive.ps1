# Cria um Dev Drive (volume ReFS de desenvolvimento) num disco virtual e grava o resultado em devdrive.log.
# Rodar no PowerShell COMO ADMINISTRADOR:
#   powershell -ExecutionPolicy Bypass -File C:\Users\Ricardo.Bueno\lume\build\windows-native\criar_devdrive.ps1
param([string]$Vhd = 'C:\DevDrive\lume.vhdx', [int]$TamanhoMB = 51200)

$log = Join-Path $PSScriptRoot 'devdrive.log'
function Log($m) { $m | Tee-Object -FilePath $log -Append }
Set-Content -Path $log -Value "criar_devdrive.ps1 - $(Get-Date -Format 's')"

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Log "administrador: $admin"
if (-not $admin) { Log 'ERRO: abra o PowerShell como administrador e rode de novo.'; exit 1 }

$os = Get-CimInstance Win32_OperatingSystem
Log "Windows: $($os.Caption) build $($os.BuildNumber)"
Log "Format-Volume aceita -DevDrive: $((Get-Command Format-Volume).Parameters.ContainsKey('DevDrive'))"
Log '--- fsutil devdrv query (estado do recurso na maquina):'
Log ((fsutil devdrv query 2>&1) -join "`n")

# letra livre, de L em diante
$usadas = (Get-Volume | Where-Object DriveLetter).DriveLetter
$letra = 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T' | Where-Object { $_ -notin $usadas } | Select-Object -First 1
Log "letra escolhida: $letra"

$dir = Split-Path -Parent $Vhd
New-Item -ItemType Directory -Force $dir | Out-Null
$livreGB = [int]((Get-PSDrive ($dir.Substring(0, 1))).Free / 1GB)
Log "espaco livre em $($dir.Substring(0, 2)): $livreGB GB (o disco virtual cresce sob demanda, ate $([int]($TamanhoMB / 1024)) GB)"

if (Test-Path $Vhd) {
    Log "o arquivo $Vhd ja existe: montando em vez de criar"
    $scriptDp = "select vdisk file=`"$Vhd`"`r`nattach vdisk`r`n"
} else {
    $scriptDp = "create vdisk file=`"$Vhd`" maximum=$TamanhoMB type=expandable`r`nattach vdisk`r`ncreate partition primary`r`nassign letter=$letra`r`n"
}
$dp = Join-Path $env:TEMP 'lume_devdrive_diskpart.txt'
[IO.File]::WriteAllText($dp, $scriptDp, [Text.Encoding]::ASCII)
Log '--- diskpart:'
Log ((diskpart /s $dp 2>&1) -join "`n")
Log "diskpart codigo de saida: $LASTEXITCODE"

if (-not (Get-Volume -DriveLetter $letra -ErrorAction SilentlyContinue)) {
    Log "ERRO: o volume $($letra): nao apareceu depois do diskpart."
    exit 1
}

Log '--- Format-Volume -DevDrive:'
try {
    $v = Format-Volume -DriveLetter $letra -DevDrive -NewFileSystemLabel LumeDev -Confirm:$false -ErrorAction Stop
    Log "formatado: $($v.FileSystemType) $([int]($v.Size / 1GB)) GB, rotulo $($v.FileSystemLabel)"
} catch {
    Log "ERRO no Format-Volume: $($_.Exception.Message)"
    Log '--- tentando pelo format.com /DevDrv:'
    Log ((cmd /c "format $($letra): /DevDrv /Q /V:LumeDev /Y" 2>&1) -join "`n")
}

Log "--- fsutil devdrv query $($letra): (resultado final):"
Log ((fsutil devdrv query "$($letra):" 2>&1) -join "`n")
Log "--- volume:"
Log ((Get-Volume -DriveLetter $letra | Format-List DriveLetter, FileSystemType, FileSystemLabel, Size, SizeRemaining | Out-String).Trim())
Log "FIM. Log gravado em $log"
