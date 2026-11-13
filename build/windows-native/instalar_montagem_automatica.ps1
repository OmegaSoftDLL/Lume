# Instala a montagem automatica do Dev Drive do Lume no boot do Windows.
# Rodar UMA vez no PowerShell COMO ADMINISTRADOR:
#   powershell -ExecutionPolicy Bypass -File C:\DevDrive\instalar_montagem_automatica.ps1
# Para desinstalar:  Unregister-ScheduledTask -TaskName 'Lume - montar Dev Drive' -Confirm:$false
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { 'ERRO: abra o PowerShell como administrador e rode de novo.'; exit 1 }
$nome = 'Lume - montar Dev Drive'
$acao = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\DevDrive\montar_lume.ps1'
$gatilhos = @((New-ScheduledTaskTrigger -AtStartup), (New-ScheduledTaskTrigger -AtLogOn))
$conta = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$cfg = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $nome -Action $acao -Trigger $gatilhos -Principal $conta -Settings $cfg -Force | Out-Null
"Tarefa '$nome' instalada (no boot e no logon, como SYSTEM)."
Start-ScheduledTask -TaskName $nome
Start-Sleep -Seconds 4
"Teste agora: L:\lume existe = $(Test-Path 'L:\lume')"
'Log das montagens: C:\DevDrive\montar_lume.log'
