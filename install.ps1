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
Write-Host "Instalando Chocolatey" -ForegroundColor Black -BackgroundColor White
iex "& {$(irm https://community.chocolatey.org/install.ps1)}"

#=================================================================================
# Instalacion de programas con SCOOP
#=================================================================================
Write-Host "Instalando git y agregando buckets utiles" -ForegroundColor Black -BackgroundColor White
scoop install git aria2
scoop bucket add ciber https://github.com/Ciberbago/ciber-bucket/
scoop bucket add extras
scoop bucket add games
scoop bucket add java
scoop bucket add nirsoft
scoop bucket add nonportable
scoop bucket add versions
scoop update
scoop config aria2-warning-enabled false

#Instalar programas
Write-Host "Instalando programas con Scoop" -ForegroundColor Black -BackgroundColor White

$apps = @(
	"advanced-ip-scanner"
	"adb"
	"anydesk"
	"antidupl.net"
	"authy"
	"autohotkey1.1"
	"blender"
	"bulk-crap-uninstaller"
	"caesium-image-compressor"
	"cpu-z"
	"crystaldiskinfo"
	"crystaldiskmark"
	"curl"
	"discord"
	"dotnet-sdk"
	"dotnet6-sdk"
	"eartrumpet"
	"etcher"
	"everything"
	"ffmpeg"
	"file-converter-np"
	"firefox"
	"furmark"
	"git"
	"gpu-z"
	"handbrake"
	"heroic-games-launcher"
	"hwinfo"
	"icaros-np"
	"irfanview"
	"k-lite-codec-pack-full-np"
	"ldplayer9-portable"
	"lockhunter"
	"losslesscut"
	"megasync"
	"neatdownloadmanager"
	"obs-studio"
	"office-365-apps-minimal-np"
	"oh-my-posh"
	"parsec-np"
	"patchcleaner"
	"powertoys"
	"prismlauncher"
	"pwsh"
	"qbittorrent"
	"scoop-search"
	"secureuxtheme"
	"sharex"
	"speedtest-cli"
	"steam"
	"tailscale"
	"teamviewer-np"
	"temurin17-jre"
	"temurin8-jre"
	"twinkle-tray"
	"vcredist-aio"
	"ventoy"
	"virtualbox-with-extension-pack-np"
	"vscode"
	"windowsdesktop-runtime"
	"windowsdesktop-runtime-lts"
	"winget"
	"wiztree"
	"yuzu"
)

foreach ($app in $apps) {
    scoop install $app
}

#Limpio la cache despues de haber descargado todo
scoop cache rm *

#=================================================================================
# Instalacion de programas con CHOCOLATEY
#=================================================================================

# Opcion util en choco
Write-Host "Instalando Programas con choco" -ForegroundColor Black -BackgroundColor White
$casa = @(
	"insync"
	"goggalaxy"
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
# Instalacion de programas con winget
#=================================================================================

winget install M2Team.NanaZip -e --accept-source-agreements --accept-package-agreements --silent

#=================================================================================
# Debloat y privacidad
#=================================================================================

#Desinstalar apps incluidas
Write-Host "Desinstalando apps incluidas con windows" -ForegroundColor Black -BackgroundColor White
$Bloatware = @(
	"*Microsoft.MicrosoftOfficeHub*"
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
	"*Family*"
	"*OnedriveSync*"
	"*Xbox*"
)

foreach ($Bloat in $Bloatware) {
    Get-AppxPackage -Name $Bloat| Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
    Write-Host "Eliminando $Bloat."
}

DISM /online /disable-feature /featurename:WindowsMediaPlayer
winget uninstall Microsoft.onedrive
Write-Host "Bloat eliminado"
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

#Creo el acceso directo al regedit para HKU y HKCR
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
New-PSDrive -PSProvider Registry -Name HKCR -Root HKEY_CLASSES_ROOT

#Desactivo sticky keys
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "506"
#Activo las extensiones de los archivos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type Dword -Value "0"
#Activo los archivos ocultos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type Dword -Value "1"

#=================================================================================
#  Variables y ajustes
#=================================================================================
#Desactivo la hibernacion
Write-Host "Desactivando hibernacion" -ForegroundColor Black -BackgroundColor White
powercfg /h off

#Descarga el archivo de autohotkey y handbrake
Write-Host "Descargando script de autohotkey y handbrake" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/autohotkey.ahk" -OutFile "$env:USERPROFILE\Documents\autohotkey.ahk"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/HBProfile.json" -OutFile "$env:USERPROFILE\Documents\HBProfile.json"

#Crear carpeta para descargar los ps1
mkdir $env:USERPROFILE\Documents\scripts

Write-Host "Descargando script para consultar IP publica" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/miip.ps1" -OutFile "$env:USERPROFILE\Documents\scripts\miip.ps1"

#Agrego programas al startup
Write-Host "Add silent flag" -ForegroundColor Black -BackgroundColor White
Copy-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Scoop Apps\ShareX.lnk" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
Copy-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Scoop Apps\Tailscale.lnk" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
Copy-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Scoop Apps\EarTrumpet.lnk" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Autohotkey.lnk" -Target "$env:USERPROFILE\Documents\autohotkey.ahk"

#Descargo el tema de rectify, lo extraigo y lo pongo en la carpeta de los temas de windows
Write-Host "Descargando e instalando el tema de Rectify11" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://github.com/Ciberbago/ciber-scripts/blob/main/rectify11.zip?raw=true" -OutFile "$env:TEMP\rectify11.zip"
7z x $env:TEMP\rectify11.zip -y -oC:\Windows\Resources\Themes

#Añade la carpeta de scripts en documentos para poder ejecutarlos desde cualquier lado
Write-Host "Se añade la ruta de scripts a las variables de entorno" -ForegroundColor Black -BackgroundColor White
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$env:USERPROFILE\Documents\scripts", "User")

#Mejoro el perfil de PS5
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kudostoy0u/pwsh10k/master/pwsh10k.omp.json" -OutFile "$env:USERPROFILE\pwsh10k.omp.json"
Add-Content -Path $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -Value ('oh-my-posh init pwsh --config ~\pwsh10k.omp.json | Invoke-Expression') -PassThru
Add-Content -Path $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -Value ('Invoke-Expression (&scoop-search --hook)') -PassThru
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
Write-Host "Recuerda importar settings para Handbrake, ademas aplica el tema de rectify11" -ForegroundColor Black -BackgroundColor White

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
#Update the windows terminal para que te deje poner los settings
Write-Host "Update the windows terminal para que te deje poner los settings y dejarla bonita" -ForegroundColor Black -BackgroundColor White
winget upgrade Microsoft.WindowsTerminal

Write-Host "Desinstala las optional features" -ForegroundColor Black -BackgroundColor White
& cmd /c start ms-settings:optionalfeatures

Write-Host "Decarga drivers y ponlos en modo minimal" -ForegroundColor Black -BackgroundColor White
Start-Process "https://www.amd.com/en/support/chipsets/amd-socket-am4/b450"
Start-Process "https://www.amd.com/en/support/graphics/amd-radeon-5700-series/amd-radeon-rx-5700-series/amd-radeon-rx-5700-xt"