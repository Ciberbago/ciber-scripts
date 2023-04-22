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

# Instalacion de SCOOP
Write-Host "Instalando scoop" -ForegroundColor Black -BackgroundColor White
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"

# Instalacion de CHOCOLATEY
Write-Host "Instalando Chocolatey" -ForegroundColor Black -BackgroundColor White
iex "& {$(irm https://community.chocolatey.org/install.ps1)}"

# Instalacion de programas con SCOOP
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
$appsAmbos = @(
	"7zip"
	"7zip19.00-helper"
	"adb"
	"advanced-ip-scanner"
	"anydesk"
	"autohotkey1.1"
	"blender"
	"caesium-image-compressor"
	"clickpaste"
	"cpu-z"
	"crystaldiskinfo"
	"crystaldiskmark"
	"curl"
	"dark"
	"dotnet-sdk"
	"dotnet6-sdk"
	"eartrumpet"
	"etcher"
	"everything"
	"ffmpeg"
	"file-converter-np"
	"firefox"
	"git"
	"hwinfo"
	"innounp"
	"k-lite-codec-pack-full-np"
	"ldplayer9-portable"
	"lockhunter"
	"losslesscut"
	"megasync"
	"neatdownloadmanager"
	"netbscanner"
	"obs-studio"
	"oh-my-posh"
	"parsec-np"
	"patchcleaner"
	"picotorrent"
	"powertoys"
	"pwsh"
	"secureuxtheme"
	"sfsu"
	"sharex"
	"speedtest-cli"
	"sudo"
	"tailscale"
	"teamviewer-np"
	"twinkle-tray"
	"vcredist-aio"
	"ventoy"
	"virtualbox-with-extension-pack-np"
	"vscode"
	"windhawk"
	"windowsdesktop-runtime"
	"windowsdesktop-runtime-lts"
	"winget"
	"wiztree"
	"ytdlp-interface"
)

$appsCasa = @(
	"antidupl.net"
	"aria2"
	"authy"
	"discord"
	"furmark"
	"gpu-z"
	"handbrake"
	"heroic-games-launcher"
	"icaros-np"
	"irfanview"
	"office-365-apps-minimal-np"
	"pmxeditor-english"
	"prismlauncher"
	"steam"
	"temurin17-jre"
	"temurin8-jre"
	"wireguard-np"
	"yuzu"
)

$appsTrabajo = @(
	"azcopy"
	"bitwarden"
	"googlechrome"
	"office-365-apps-np"
	"openvpn-connect"
	"openwithview"
	"pdfsam"
	"rdp-plus"
	"scrcpy"
	"vcredist2015"
	"win-ps2exe"
	"winbox"
)

If ($respuesta -eq 1){
	scoop install $appsAmbos; scoop install $appsCasa
}
else{
	scoop install $appsAmbos; scoop install $appsTrabajo
}

#Limpio la cache despues de haber descargado todo
scoop cache rm *

# Instalacion de programas con CHOCOLATEY
Write-Host "Instalando Programas con choco" -ForegroundColor Black -BackgroundColor White
$casa = @(
	"insync"
	"goggalaxy"
)

If ($respuesta -eq 1){
	choco install $casa -y --force
}
else {
	Write-Host "No se instala nada desde chocolatey"
}
# Instalacion de programas con winget
winget install M2Team.NanaZip -e --accept-source-agreements --accept-package-agreements --silent

#Bloatware
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

Write-Host "Desinstalando apps incluidas con windows" -ForegroundColor Black -BackgroundColor White

$Bloatware = @(
	"*Microsoft.MicrosoftOfficeHub*"
	"*Microsoft.ZuneVideo*"
	"*Microsoft.ZuneMusic*"
	"*Microsoft.WindowsNotepad*"
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
	"*Xbox*"
)
$BloatwareCasa = @(
	"*OnedriveSync*"
	"*MicrosoftTeams*"
)

If ($respuesta -eq 1){
#------
foreach ($Bloat in $Bloatware) {
    Get-AppxPackage -Name $Bloat| Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
    Write-Host "Eliminando $Bloat."
}
foreach ($Bloat in $BloatwareCasa) {
    Get-AppxPackage -Name $Bloat| Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
    Write-Host "Eliminando $Bloat."
}
DISM /online /disable-feature /featurename:WindowsMediaPlayer
#Deshabilitar onedrive
winget uninstall Microsoft.Onedrive -h --accept-source-agreements
Write-Host "Deshabilitando OneDrive" -ForegroundColor Black -BackgroundColor White
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" | Out-Null
    }
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1
Write-Host "Deshabilitando OneDrive" -ForegroundColor Black -BackgroundColor White
#------
}
else {
	Write-Host "Onedrive queda habilitado" -ForegroundColor Black -BackgroundColor White
	foreach ($Bloat in $Bloatware) {
    Get-AppxPackage -Name $Bloat| Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
    Write-Host "Eliminando $Bloat."
	}
	DISM /online /disable-feature /featurename:WindowsMediaPlayer
}

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

#Crear carpeta para descargar los ps1
mkdir $env:USERPROFILE\Documents\scripts

#Descarga de archivos
Write-Host "Descargando script de autohotkey y handbrake" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/autohotkey.ahk" -OutFile "$env:USERPROFILE\Documents\autohotkey.ahk"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/HBProfile.json" -OutFile "$env:USERPROFILE\Documents\HBProfile.json"
Invoke-WebRequest -Uri "https://github.com/Ciberbago/ciber-scripts/blob/main/rectify11.zip?raw=true" -OutFile "$env:TEMP\rectify11.zip"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kudostoy0u/pwsh10k/master/pwsh10k.omp.json" -OutFile "$env:USERPROFILE\pwsh10k.omp.json"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/Caskaydia.ttf" -OutFile "C:\Windows\fonts\Caskaydia.ttf"

#Agrego programas al startup
function Crear-AccesoDirecto {
    param(
        [string]$Ubicacion,
        [string]$Destino,
        [string]$Flag
    )


    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut([Environment]::GetFolderPath('Startup')+$Ubicacion)
    $Shortcut.TargetPath = $Destino
    $Shortcut.Arguments = $Flag
    $Shortcut.Save()
	$Shortcut
}

Crear-AccesoDirecto "\ShareX.lnk" "$env:USERPROFILE\scoop\apps\sharex\current\ShareX.exe" " -silent"
Crear-AccesoDirecto "\Tailscale.lnk" "$env:USERPROFILE\scoop\apps\tailscale\current\tailscale-ipn.exe" ""
Crear-AccesoDirecto "\EarTrumpet.lnk" "$env:USERPROFILE\scoop\apps\eartrumpet\current\EarTrumpet.exe" ""
Crear-AccesoDirecto "\Windhawk.lnk" "$env:USERPROFILE\scoop\apps\windhawk\current\Windhawk\windhawk.exe" "-tray-only"
Crear-AccesoDirecto "\Autohotkey.lnk" "$env:USERPROFILE\Documents\autohotkey.ahk" ""

#Descargo el tema de rectify, lo extraigo y lo pongo en la carpeta de los temas de windows
Write-Host "Instalando el tema de Rectify11" -ForegroundColor Black -BackgroundColor White
7z x $env:TEMP\rectify11.zip -y -oC:\Windows\Resources\Themes

#Añade la carpeta de scripts en documentos para poder ejecutarlos desde cualquier lado
Write-Host "Se añade la ruta de scripts a las variables de entorno" -ForegroundColor Black -BackgroundColor White
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$env:USERPROFILE\Documents\scripts", "User")

#Mejoro el perfil de PS5
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}
Add-Content -Path $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -Value ('oh-my-posh init pwsh --config ~\pwsh10k.omp.json | Invoke-Expression') -PassThru
Add-Content -Path $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -Value ('Invoke-Expression (&sfsu hook)') -PassThru
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
#Drivers chipset, gpu y lan
Start-Process "https://www.amd.com/en/support/chipsets/amd-socket-am4/b450"
Start-Process "https://www.amd.com/en/support/graphics/amd-radeon-5700-series/amd-radeon-rx-5700-series/amd-radeon-rx-5700-xt"
Start-Process "https://download.gigabyte.com/FileList/Driver/mb_driver_654_w11_1168.007.0318.2022.zip?v=07466d7005ac1718a94c1669f6d329b3"