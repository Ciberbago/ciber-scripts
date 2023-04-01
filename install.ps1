Write-Host "   _____   _   _                              _____                 _             _   _                "
Write-Host "  / ____| (_) | |                            |_   _|               | |           | | | |               "
Write-Host " | |       _  | |__     ___   _ __   ______    | |    _ __    ___  | |_    __ _  | | | |   ___   _ __  "
Write-Host " | |      | | | '_ \   / _ \ | '__| |______|   | |   | '_ \  / __| | __|  / _` | | | | |  / _ \ | '__| "
Write-Host " | |____  | | | |_) | |  __/ | |              _| |_  | | | | \__ \ | |_  | (_| | | | | | |  __/ | |    "
Write-Host "  \_____| |_| |_.__/   \___| |_|             |_____| |_| |_| |___/  \__|  \__,_| |_| |_|  \___| |_|    "
Write-Host ""
Write-Host ""
Write-Host "EPIC!"
pause

$respuesta = Read-Host "`r`n`r`n`r`nEsta instalación es para...
[1] Personal
[2] Trabajo
"
#Aplico el tema oscuro desde el principio
& cmd /c "C:\Windows\Resources\Themes\dark.theme & timeout /t 03 /nobreak > NUL & taskkill /f /im systemsettings.exe"
Set-ExecutionPolicy Unrestricted

#=================================================================================
# Instalacion de SCOOP
#=================================================================================

Write-Host "Instalando scoop" -ForegroundColor Black -BackgroundColor White
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"

#=================================================================================
# Instalacion de CHOCOLATEY
#=================================================================================

# Se habilita la instalacion de scripts externos para instalar chocolatey
Write-Host "Instalando Chocolatey" -ForegroundColor Black -BackgroundColor White

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco feature enable -n=useRememberedArgumentsForUpgrades

#=================================================================================
# Instalacion de programas con winget
#=================================================================================

winget install m2team.nanazip -e --accept-source-agreements --accept-package-agreements --silent

#=================================================================================
# Instalacion de programas con SCOOP
#=================================================================================

#Agregar buckets

Write-Host "Agregando buckets utiles" -ForegroundColor Black -BackgroundColor White
scoop install git
scoop bucket add games
scoop bucket add extras
scoop bucket add nirsoft
scoop bucket add nonportable
scoop bucket add versions
scoop bucket add java
scoop update

#Instalar programas
Write-Host "Instalando programas con Scoop" -ForegroundColor Black -BackgroundColor White

$apps = @(
	"advanced-ip-scanner",
	"adb",
	"anydesk",
	"authy",
	"autohotkey1.1",
	"blender",
	"bulk-crap-uninstaller",
	"cpu-z",
	"crystaldiskinfo",
	"crystaldiskmark",
	"curl",
	"discord",
	"eartrumpet",
	"etcher",
	"everything",
	"ffmpeg",
	"file-converter-np",
	"firefox",
	"furmark",
	"git",
	"gpu-z",
	"handbrake",
	"heroic-games-launcher",
	"hwinfo",
	"icaros-np",
	"irfanview",
	"k-lite-codec-pack-full-np",
	"lockhunter",
	"losslesscut",
	"megasync",
	"obs-studio",
	"office-365-apps-np",
	"parsec-np",
	"patchcleaner",
	"powertoys",
	"prismlauncher",
	"pwsh",
	"qbittorrent",
	"secureuxtheme",
	"sharex",
	"speedtest-cli",
	"steam",
	"tailscale",
	"teamviewer-np",
	"temurin17-jre",
	"temurin8-jre",
	"twinkle-tray",
	"vcredist-aio",
	"ventoy",
	"virtualbox-with-extension-pack-np",
	"vscode",
	"windowsdesktop-runtime",
	"wiztree",
	"yuzu"
)

foreach ($app in $apps) {
    scoop install $app
}

#=================================================================================
# Instalacion de programas con CHOCOLATEY
#=================================================================================

# Opcion util en choco
Write-Host "Instalando Programas con choco" -ForegroundColor Black -BackgroundColor White
$casa = @(
	"amd-ryzen-chipset"
	"internet-download-manager"
	"insync"
)

$trabajo = @(
	"advanced-ipscanner"
	"cpu-z"
	"crystaldiskinfo"
	"crystaldiskmark"
	"eartrumpet"
	"everything"
	"ffmpeg"
	"file-converter"
	"hwinfo"
	"irfanview"
	"irfanviewplugins"
	"k-litecodecpackfull"
	"powershell-core"
	"powertoys"
	"qbittorrent"
	"sharex"
	"tailscale"
	"teamviewer"
	"virtualbox"
	"vscode"
	"wiztree"
)

If ($respuesta -eq 1){
	choco install $casa -y --force
}
else {
	choco install $trabajo -y --force
}
#=================================================================================
# Debloat y privacidad
#=================================================================================

#Desinstalar apps incluidas
Write-Host "Desinstalando apps incluidas con windows" -ForegroundColor Black -BackgroundColor White
$Bloatware = @(
	"*Microsoft.MicrosoftOfficeHub*"
	"*Microsoft.Windows.Photos*"
	"*Microsoft.ZuneVideo*"
	"*Microsoft.ZuneMusic*"
	"*Microsoft.WindowsNotepad*"
	"*MicrosoftTeams*"
	"*Microsoft.ScreenSketch*"
	"*Microsoft.WindowsMaps*"
	"*Microsoft.PowerAutomateDesktop*"
	"*Microsoft.People*"
	"*Microsoft.MicrosoftStickyNotes*"
	"*Microsoft.MicrosoftSolitaireCollection*"
	"*Microsoft.Getstarted*"
	"*Microsoft.windowscommunicationsapps*"
	"*Microsoft.BingWeather*"
	"*Microsoft.BingNews*"
	"*Microsoft.Todos*"
	"*Microsoft.GetHelp*"
	"*Microsoft.549981C3F5F10*"
	"*Microsoft.XboxGamingOverlay*"
	"*Microsoft.GamingApp*"
	"*Clipchamp.Clipchamp*"
	"*Microsoft.YourPhone*"
	"*Microsoft.WindowsFeedbackHub*"
	"*Paint*"
)

foreach ($Bloat in $Bloatware) {
    Get-AppxPackage -Name $Bloat| Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
    Write-Host "Eliminando $Bloat."
}

DISM /online /disable-feature /featurename:WindowsMediaPlayer

Write-Host "Bloat eliminado"
Get-AppxPackage -Name "*Paint*"| Remove-AppxPackage


# ----------------------------------------------------------
# Deshabilito Onedrive
# ----------------------------------------------------------
If ($respuesta -eq 1){
Write-Host "Deshabilitando OneDrive" -ForegroundColor Black -BackgroundColor White
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" | Out-Null
    }

Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1
Write-Host "Deshabilitando OneDrive" -ForegroundColor Black -BackgroundColor White
Stop-Process -Name "OneDrive" -ErrorAction SilentlyContinue
Start-Sleep -s 2
$onedrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
If (!(Test-Path $onedrive)) {
        $onedrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
    }

Start-Process $onedrive "/uninstall" -NoNewWindow -Wait
Start-Sleep -s 2
Stop-Process -Name "explorer" -ErrorAction SilentlyContinue
Start-Sleep -s 2
Remove-Item -Path "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue
If (!(Test-Path "HKCR:")) {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    }

Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
Write-Host "Quitado OneDrive" -ForegroundColor Black -BackgroundColor White
} 
else {
	Write-Host "Onedrive queda habilitado" -ForegroundColor Black -BackgroundColor White
}
# ----------------------------------------------------------
# ----------------------------------------------------------


#Tweaks de privacidad sacado del script de titus

If ($respuesta -eq 1){
Write-Host "Disabling Telemetry..." -ForegroundColor Black -BackgroundColor White
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Type DWord -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 0
Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" | Out-Null
Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\ProgramDataUpdater" | Out-Null
Disable-ScheduledTask -TaskName "Microsoft\Windows\Autochk\Proxy" | Out-Null
Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" | Out-Null
Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" | Out-Null
Disable-ScheduledTask -TaskName "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" | Out-Null
}
else {
	Write-Host "No se aplican ajustes de privacidad de O&O, solo ajustes del registro" -ForegroundColor Black -BackgroundColor White
	Write-Host "Disabling Telemetry..." -ForegroundColor Black -BackgroundColor White
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 0
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" | Out-Null
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\ProgramDataUpdater" | Out-Null
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Autochk\Proxy" | Out-Null
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" | Out-Null
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" | Out-Null
	Disable-ScheduledTask -TaskName "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" | Out-Null
	Write-Host "Telemtria deshabilitada" -ForegroundColor Black -BackgroundColor White
}
#Creo el acceso directo al regedit para HKU y HKCR
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
New-PSDrive -PSProvider Registry -Name HKCR -Root HKEY_CLASSES_ROOT


#Desactivo sticky keys
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "506"

#Activo las extensiones de los archivos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type Dword -Value "0"

#Activo los archivos ocultos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type Dword -Value "1"

#Cambio el editor de autohotkey a vscode por default
#Set-ItemProperty -Path "HKCR:\AutoHotkeyScript\Shell\Edit\Command" -Name "(Default)" -Value '"C:\Users\xhjlj\scoop\apps\vscode\current\Code.exe" %1'

#=================================================================================
#  Variables y ajustes
#=================================================================================

#Desactivo la hibernacion
Write-Host "Desactivando hibernacion" -ForegroundColor Black -BackgroundColor White
powercfg /h off

#Descarga el archivo de autohotkey
Write-Host "Descargando script de autohotkey" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/autohotkey.ahk" -OutFile "$env:USERPROFILE\Documents\autohotkey.ahk"

#Descarga el archivo de handbrake para crear el perfil de codificacion eficiente
Write-Host "Descargando perfil de handbrake" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/HBProfile.json" -OutFile "$env:USERPROFILE\Documents\HBProfile.json"

#Descarga el archivo de cofig de winaero tweaker
Write-Host "Descargando perfil de handbrake" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/Winaero.ini" -OutFile "$env:USERPROFILE\Documents\Winaero.ini"

#Write-Host "Descargando archivo de config de windows terminal" -ForegroundColor Black -BackgroundColor White
#Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/terminal.json" -OutFile "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

#Crear carpeta para descargar los ps1
mkdir $env:USERPROFILE\Documents\scripts

Write-Host "Descargando script para iniciar sesion en O365" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/office.ps1" -OutFile "$env:USERPROFILE\Documents\scripts\office.ps1"

Write-Host "Descargando script para consultar licencias en O365" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/licencias.ps1" -OutFile "$env:USERPROFILE\Documents\scripts\licencias.ps1"

Write-Host "Descargando script para cambiar contraseñas en O365" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/pass.ps1" -OutFile "$env:USERPROFILE\Documents\scripts\pass.ps1"

Write-Host "Descargando script para consultar IP publica" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/miip.ps1" -OutFile "$env:USERPROFILE\Documents\scripts\miip.ps1"

Write-Host "Descargando archivo de regedit y cmd para resetear IDM trial" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/IDMTrialReset.reg" -OutFile "$env:USERPROFILE\Documents\scripts\IDMTrialReset.reg"

#Descargo el tema de rectify, lo extraigo y lo pongo en la carpeta de los temas de windows
Write-Host "Descargando e instalando el tema de Rectify11" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://github.com/Ciberbago/ciber-scripts/blob/main/rectify11.zip?raw=true" -OutFile "$env:TEMP\rectify11.zip"
7z x $env:TEMP\rectify11.zip -y -oC:\Windows\Resources\Themes

#Recargo las variables para poder añadir otra
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

#Añade la carpeta de scripts en documentos para poder ejecutarlos desde cualquier lado
Write-Host "Se añade la ruta de scripts a las variables de entorno" -ForegroundColor Black -BackgroundColor White
$NewPath2 = "$env:USERPROFILE\Documents\scripts"
$Target = [System.EnvironmentVariableTarget]::Machine
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ";$NewPath2", $Target)

#Mejoro el perfil de PS5
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kudostoy0u/pwsh10k/master/pwsh10k.omp.json" -OutFile "$env:USERPROFILE\pwsh10k.omp.json"
Add-Content -Path $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -Value ('oh-my-posh init pwsh --config ~\pwsh10k.omp.json | Invoke-Expression') -PassThru
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/Caskaydia.ttf" -OutFile "C:\Windows\fonts\Caskaydia.ttf"
C:\Windows\fonts\Caskaydia.ttf

#Copio el perfil de PS5 para PS7
Write-Host "Copio el perfil de PS5 para PS7" -ForegroundColor Black -BackgroundColor White
xcopy $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 $env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1*

#Borro la carpeta de keys de YUZU y hago un link de la que ya las tiene en el disco D
If ($respuesta -eq 1){
Remove-Item "$env:USERPROFILE\scoop\apps\yuzu\current\user\keys"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\scoop\apps\yuzu\current\user\keys" -Target "D:\Emuladores\Switch\keys"
}
else {
	Write-Host "No se hace nada de yuzu" -ForegroundColor Black -BackgroundColor White
}
#Recordatorios MANUAL
Write-Host "Recuerda importar settings e importar settings para Winaero y Handbrake, ademas aplica el tema de rectify11" -ForegroundColor Black -BackgroundColor White

#Recordatorios MANUAL2
If ($respuesta -eq 1){
Write-Host "Recuerda instalar localizar juegos en Battle net, Heroic y Steam" -ForegroundColor Black -BackgroundColor White
Start-Process "https://www.blizzard.com/download/confirmation?product=bnetdesk"

#Recordatorios MANUAL2
Write-Host "Recuerda iniciar sesion con ambas cuentas en INSYNC" -ForegroundColor Black -BackgroundColor White

#Recordatorios MANUAL2
Write-Host "Recuerda agregar a las ubicaciones de red el nas y poco x3" -ForegroundColor Black -BackgroundColor White
}
else {
	Write-Host "No se hace nada de cosas personales" -ForegroundColor Black -BackgroundColor White
}
#Update the windows terminal para que te deje poner los settings y dejarla bonita con winfetch al inicio en PWSH
Write-Host "Update the windows terminal para que te deje poner los settings y dejarla bonita con winfetch al inicio en PWSH" -ForegroundColor Black -BackgroundColor White
winget upgrade Microsoft.WindowsTerminal