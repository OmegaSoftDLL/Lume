# Monta o Dev Drive do Lume (C:\DevDrive\lume.vhdx) se ainda nao estiver montado, e confere a letra L:.
# Pode ser rodado a qualquer momento; a tarefa agendada "Lume - montar Dev Drive" chama este script no boot.
$vhd = 'C:\DevDrive\lume.vhdx'
$log = 'C:\DevDrive\montar_lume.log'
function Log($m) { "$(Get-Date -Format s) $m" | Add-Content $log }
try {
    if (-not (Test-Path $vhd)) { Log "ERRO: $vhd nao existe"; exit 1 }
    $img = Get-DiskImage -ImagePath $vhd
    if (-not $img.Attached) { Mount-DiskImage -ImagePath $vhd | Out-Null; Log 'disco montado' } else { Log 'disco ja estava montado' }
    Start-Sleep -Seconds 2
    $vol = Get-DiskImage -ImagePath $vhd | Get-Disk | Get-Partition | Where-Object { $_.Type -ne 'Reserved' } | Get-Volume
    if ($vol.DriveLetter -ne 'L') {
        Get-DiskImage -ImagePath $vhd | Get-Disk | Get-Partition | Where-Object { $_.Type -ne 'Reserved' } | Set-Partition -NewDriveLetter L
        Log "letra ajustada para L: (era '$($vol.DriveLetter)')"
    }
    if (Test-Path 'L:\lume') { Log 'L:\lume disponivel' } else { Log 'AVISO: L: montado, mas L:\lume nao encontrado' }
} catch { Log "ERRO: $($_.Exception.Message)"; exit 1 }
