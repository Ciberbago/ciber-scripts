Write-Host "____ _ ___  ____ ____    _ _  _ ____ ___ ____ _    _    ____ ____ "
Write-Host "|    | |__] |___ |__/ __ | |\ | [__   |  |__| |    |    |___ |__/ "
Write-Host "|___ | |__] |___ |  \    | | \| ___]  |  |  | |___ |___ |___ |  \ "
pause
$respuesta = Read-Host "`r`n`r`n`r`nEsta instalación es para... [1] Personal [2] Trabajo"
#Aplico el tema oscuro desde el principio
& cmd /c "C:\Windows\Resources\Themes\dark.theme & timeout /t 03 /nobreak > NUL & taskkill /f /im systemsettings.exe"
Set-ExecutionPolicy Unrestricted

# Instalacion de SCOOP
Write-Host "Instalando scoop" -ForegroundColor Black -BackgroundColor White
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
# Instalacion de CHOCOLATEY
Write-Host "Instalando Chocolatey" -ForegroundColor Black -BackgroundColor White
iex "& {$(irm https://community.chocolatey.org/install.ps1)}"
###### Instalacion de programas con SCOOP ######
Write-Host "Instalando git y agregando buckets utiles" -ForegroundColor Black -BackgroundColor White
scoop install git aria2
scoop config aria2-enabled false
scoop config aria2-warning-enabled false
scoop bucket add ciber https://github.com/Ciberbago/ciber-bucket/
$b = @("extras", "games", "java", "nirsoft", "nonportable", "versions")
$b | ForEach-Object {scoop bucket add $_}
scoop update
#Instalar programas
Write-Host "Instalando programas con Scoop" -ForegroundColor Black -BackgroundColor White
$appsAmbos = @(
	"7zip"
	"7zip19.00-helper"
	"adb"
	"advanced-ip-scanner"
	"autohotkey1.1"
	"blender-mirror"
	"caesium-image-compressor"
	"clickpaste"
	"cpu-z"
	"crystaldiskinfo"
	"crystaldiskmark"
	"curl"
	"dark"
	"ddu"
	"dotnet-sdk"
	"dotnet6-sdk"
	"eartrumpet"
	"etcher"
	"everything"
	"ffmpeg"
	"firefox"
	"git"
	"hwinfo"
	"innounp"
	"iperf3"
	"k-lite-codec-pack-full-np"
	"ldplayer9-portable"
	"lanspeedtest"
	"lockhunter"
	"losslesscut"
	"macrorit-partition-expert"
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
	"ddu"
	"discord"
	"furmark"
	"gpu-z"
	"handbrake"
	"heroic-games-launcher"
	"icaros-np"
	"irfanview"
	"locale-emulator"
	"mcedit2"
	"office-365-apps-minimal-np"
	"pmxeditor-english"
	"prismlauncher"
	"steam"
	"steamcleaner"
	"temurin17-jre"
	"temurin8-jre"
	"wireguard-np"
	"yuzu"
)
$appsTrabajo = @(
	"azcopy"
	"bitwarden"
	"googlechrome"
	"nvcleanstall"
	"office-365-apps-np"
	"openvpn-connect"
	"openwithview"
	"pdfsam"
	"rdp-plus"
	"scrcpy"
	"win-ps2exe"
	"winbox"
)
If ($respuesta -eq 1){ scoop install $appsAmbos; scoop install $appsCasa }
else{ scoop install $appsAmbos; scoop install $appsTrabajo }
#Limpio la cache despues de haber descargado todo
scoop cache rm *
###### Instalacion de programas con CHOCOLATEY ########
Write-Host "Instalando Programas con choco" -ForegroundColor Black -BackgroundColor White
$casa = @("insync",	"goggalaxy", "anydesk.install")
$trabajo = @("PowerBi","anydesk.install")
If ($respuesta -eq 1){ choco install $casa -y --force }
else { choco install $trabajo -y --force }
###### Instalacion de programas con winget ######
$winApps = @("M2Team.NanaZip")
winget install $winApps -e --accept-source-agreements --accept-package-agreements --silent

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
	If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
			New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" | Out-Null
		}
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1
	Write-Host "Deshabilitado OneDrive" -ForegroundColor Black -BackgroundColor White
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

#Crear carpeta para descargar los ps1
mkdir $env:USERPROFILE\Documents\scripts
#Descarga de archivos
Write-Host "Descargando script de autohotkey y handbrake" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kudostoy0u/pwsh10k/master/pwsh10k.omp.json" -OutFile "$env:USERPROFILE\pwsh10k.omp.json"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/autohotkey.ahk" -OutFile "$env:USERPROFILE\Documents\autohotkey.ahk"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/HBProfile.json" -OutFile "$env:USERPROFILE\Documents\HBProfile.json"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/gif2mp4.ps1" -OutFile "$env:USERPROFILE\Documents\scripts\gif2mp4.ps1"
Invoke-WebRequest -Uri "https://github.com/Ciberbago/ciber-scripts/blob/main/rectify11.zip?raw=true" -OutFile "$env:TEMP\rectify11.zip"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/Caskaydia.ttf" -OutFile "C:\Windows\fonts\Caskaydia.ttf"

#Desactivo sticky keys
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "506"
#Activo las extensiones de los archivos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type Dword -Value "0"
#Activo los archivos ocultos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type Dword -Value "1"
#Desactivo el grabar juegos con la app de xbox (error ms-gamingoverlay)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type Dword -Value "0"
#Desactivo la hibernacion
powercfg /h off
#Añade la carpeta de scripts en documentos para poder ejecutarlos desde cualquier lado
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$env:USERPROFILE\Documents\scripts", "User")

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
#Añado programas al startup
Crear-AccesoDirecto "\Autohotkey.lnk" "$env:USERPROFILE\Documents\autohotkey.ahk" ""
Crear-AccesoDirecto "\EarTrumpet.lnk" "$env:USERPROFILE\scoop\apps\eartrumpet\current\EarTrumpet.exe" ""
Crear-AccesoDirecto "\ShareX.lnk" "$env:USERPROFILE\scoop\apps\sharex\current\ShareX.exe" " -silent"
Crear-AccesoDirecto "\Tailscale.lnk" "$env:USERPROFILE\scoop\apps\tailscale\current\tailscale-ipn.exe" ""
Crear-AccesoDirecto "\Windhawk.lnk" "$env:USERPROFILE\scoop\apps\windhawk\current\Windhawk\windhawk.exe" "-tray-only"
#Añado carpetas al quick access
$qa = new-object -com shell.application
$qa.Namespace("E:\jaimedrive").Self.InvokeVerb("pintohome")
$qa.Namespace("E:\cybr34").Self.InvokeVerb("pintohome")
$qa.Namespace("$env:USERPROFILE\scoop\apps\sharex\current\ShareX\Screenshots").Self.InvokeVerb("pintohome")
#Descargo el tema de rectify, lo extraigo y lo pongo en la carpeta de los temas de windows
7z x $env:TEMP\rectify11.zip -y -oC:\Windows\Resources\Themes
#Mejoro el perfil de PS5
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}
Add-Content -Path $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -Value ('oh-my-posh --init --shell pwsh --config ~\pwsh10k.omp.json | Invoke-Expression') -PassThru
Add-Content -Path $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -Value ('Invoke-Expression (&sfsu hook)') -PassThru
C:\Windows\fonts\Caskaydia.ttf
#Copio el perfil de PS5 para PS7
xcopy $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 $env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1*

#Borro la carpeta de keys de YUZU y hago un link de la que ya las tiene en el disco D
If ($respuesta -eq 1){
Remove-Item "$env:USERPROFILE\scoop\apps\yuzu\current\user\keys"
	if ((Test-Path -Path "D:\Emuladores\Switch\keys")) {
		New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\scoop\apps\yuzu\current\user\keys" -Target "D:\Emuladores\Switch\keys"
	}
	Write-Host "No se detecto el disco D"
}
else {
	Write-Host "No se hace nada de yuzu" -ForegroundColor Black -BackgroundColor White
}
#Recordatorios MANUAL
Write-Host "Recuerda importar settings para Handbrake, ademas aplica el tema de rectify11" -ForegroundColor Black -BackgroundColor White
#Instalacion battlenet
If ($respuesta -eq 1){
Write-Host "Recuerda instalar localizar juegos en Battle net, Heroic y Steam" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://us.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe&id=undefined" -OutFile "$env:temp\bnet.exe"
Start-process -Wait $env:temp\bnet.exe -ArgumentList '--lang=esMX --installpath="C:\Program Files (x86)\Battle.net"'

Write-Host "Recuerda iniciar sesion con ambas cuentas en INSYNC" -ForegroundColor Black -BackgroundColor White
Write-Host "Recuerda agregar a las ubicaciones de red el nas y poco x3" -ForegroundColor Black -BackgroundColor White
}
else {
	Write-Host "No se hace nada de cosas personales" -ForegroundColor Black -BackgroundColor White
}
Write-Host "Update the windows terminal para que te deje poner los settings y dejarla bonita" -ForegroundColor Black -BackgroundColor White
winget upgrade Microsoft.WindowsTerminal
Write-Host "Desinstala las optional features" -ForegroundColor Black -BackgroundColor White
& cmd /c start ms-settings:optionalfeatures

Write-Host "Decarga drivers y ponlos en modo minimal" -ForegroundColor Black -BackgroundColor White
#Drivers chipset, gpu y lan
Start-Process "https://www.amd.com/en/support/chipsets/amd-socket-am4/b450"
Start-Process "https://www.amd.com/en/support/graphics/amd-radeon-5700-series/amd-radeon-rx-5700-series/amd-radeon-rx-5700-xt"
Start-Process "https://download.gigabyte.com/FileList/Driver/mb_driver_654_w11_1168.007.0318.2022.zip?v=07466d7005ac1718a94c1669f6d329b3"