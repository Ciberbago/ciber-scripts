Write-Host "   _____   _   _                              _____                 _             _   _                "
Write-Host "  / ____| (_) | |                            |_   _|               | |           | | | |               "
Write-Host " | |       _  | |__     ___   _ __   ______    | |    _ __    ___  | |_    __ _  | | | |   ___   _ __  "
Write-Host " | |      | | | '_ \   / _ \ | '__| |______|   | |   | '_ \  / __| | __|  / _` | | | | |  / _ \ | '__| "
Write-Host " | |____  | | | |_) | |  __/ | |              _| |_  | | | | \__ \ | |_  | (_| | | | | | |  __/ | |    "
Write-Host "  \_____| |_| |_.__/   \___| |_|             |_____| |_| |_| |___/  \__|  \__,_| |_| |_|  \___| |_|    "

pause

#=================================================================================
# Instalacion de WINGET
#=================================================================================

Write-Host "Instalando Winget" -ForegroundColor Black -BackgroundColor White
Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
$nid = (Get-Process AppInstaller).Id
Wait-Process -Id $nid
Write-Host "Winget instalado" -ForegroundColor Black -BackgroundColor White

#=================================================================================
# Instalacion de SCOOP
#=================================================================================

#Instalar scoop
Write-Host "Instalando scoop" -ForegroundColor Black -BackgroundColor White
iwr -useb get.scoop.sh -outfile "$env:TEMP\install.ps1"
cd $env:TEMP
set-executionpolicy remotesigned
.\install.ps1 -RunAsAdmin
cd ~

#=================================================================================
# Instalacion de CHOCOLATEY
#=================================================================================

# Se habilita la instalacion de scripts externos para instalar chocolatey
Write-Host "Instalando Chocolatey" -ForegroundColor Black -BackgroundColor White
Set-ExecutionPolicy AllSigned -Force
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco feature enable -n=useRememberedArgumentsForUpgrades

#=================================================================================
# Instalacion de programas con WINGET
#=================================================================================

#Instalar nanazip desde winget
Write-Host "Instalando programas con winget" -ForegroundColor Black -BackgroundColor White
winget install m2team.nanazip
winget install lockhunter
winget install heroic

#=================================================================================
# Instalacion de programas con SCOOP
#=================================================================================

#Instalar git, pshazz para terminal bonita y neofetch
Write-Host "Instalando git y utilidades cli" -ForegroundColor Black -BackgroundColor White
scoop install git pshazz winfetch speedtest-cli

#Agregar buckets
Write-Host "Agregando buckets utiles" -ForegroundColor Black -BackgroundColor White
scoop bucket add games
scoop bucket add extras
scoop bucket add nirsoft

#Instalar programas que ocupan buckets extras
Write-Host "Instalando programas que ocupan buckets extras" -ForegroundColor Black -BackgroundColor White
scoop install polymc losslesscut secureuxtheme

#=================================================================================
# Instalacion de programas con CHOCOLATEY
#=================================================================================

# Opcion util en choco
Write-Host "Instalando Programas con choco" -ForegroundColor Black -BackgroundColor White
$programas = @(
	"advanced-ipscanner"
	"amd-ryzen-chipset"
	"autohotkey"
	"blender"
	"bulk-crap-uninstaller"
	"cpu-z"
	"crystaldiskinfo"
	"crystaldiskmark"
	"discord"
	"dopamine"
	"eartrumpet"
	"epicgameslauncher"
	"everything"
	"ffmpeg"
	"file-converter"
	"gpu-z"
	"handbrake"
	"hwinfo"
	"insync"
	"irfanview"
	"irfanviewplugins"
	"k-litecodecpackfull"
	"msiafterburner"
	"notepadplusplus"
	"obs-studio"
	"parsec"
	"powershell-core"
	"qbittorrent"
	"sharex"
	"steam-client"
	"teamviewer"
	"temurin17jre"
	"temurin8jre"
	"virtualbox"
	"winaero-tweaker"
	"wiztree"
	"zerotier-one"
)
choco install $programas -y --force

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
)

foreach ($Bloat in $Bloatware) {
    Get-AppxPackage -Name $Bloat| Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
    Write-Host "Eliminando $Bloat."
}

Write-Host "Bloat eliminado"

DISM /online /disable-feature /featurename:WindowsMediaPlayer

#Deshabilito Onedrive
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

#Tweaks de privacidad sacado del script de titus
Write-Host "Running O&O Shutup with Recommended Settings" -ForegroundColor Black -BackgroundColor White
Import-Module BitsTransfer
Start-BitsTransfer -Source "https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/ooshutup10.cfg" -Destination ooshutup10.cfg
Start-BitsTransfer -Source "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -Destination OOSU10.exe
./OOSU10.exe ooshutup10.cfg /quiet
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

#Creo el acceso directo al regedit para HKU
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
#Hago que la fecha corta tenga el nombre del día y mes
Set-ItemProperty -Path "HKU:\S-1-5-21-3435970072-2076227087-819996100-1001\Control Panel\International" -Name "sShortDate" -Type String -Value "ddd dd/MMM/yyyy"

#Desactivo sticky keys
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "506"

#Activo las extensiones de los archivos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type Dword -Value "0"

#Activo los archivos ocultos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type Dword -Value "1"

#=================================================================================
#  Variables y ajustes
#=================================================================================

#Activo el modo oscuro
Write-Host "Activando modo oscuro" -ForegroundColor Black -BackgroundColor White
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0 -Type Dword -Force
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0 -Type Dword -Force

#Desactivo la hibernacion
Write-Host "Desactivando hibernacion" -ForegroundColor Black -BackgroundColor White
powercfg /h off

#Descarga el archivo de autohotkey
Write-Host "Descargando script de autohotkey" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/autohotkey.ahk" -OutFile "$env:USERPROFILE\Documents\autohotkey.ahk"

#Descarga el archivo de handbrake para crear el perfil de codificacion eficiente
Write-Host "Descargando perfil de handbrake" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/HBProfile.json" -OutFile "$env:USERPROFILE\Documents\HBProfile.json"

#Descarga el archivo de cofig de winaero tweaker
Write-Host "Descargando perfil de handbrake" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/Winaero.ini" -OutFile "$env:USERPROFILE\Documents\Winaero.ini"

#Crea el script para sincronizar musica local con el nas
Write-Host "Creando script para music sync" -ForegroundColor Black -BackgroundColor White
echo "robocopy E:\jaimedrive\Music \\192.168.100.250\nas\music /r:60 /w:5 /PURGE /MIR /MT:64" | out-file -encoding ascii $env:USERPROFILE\Documents\sync.cmd

#Descargo el tema de rectify, lo extraigo y lo pongo en la carpeta de los temas de windows
Write-Host "Descargando e instalando el tema de Rectify11" -ForegroundColor Black -BackgroundColor White
Invoke-WebRequest -Uri "https://github.com/Ciberbago/ciber-scripts/blob/main/rectify11.zip?raw=true" -OutFile "$env:TEMP\rectify11.zip"
7z x $env:TEMP\rectify11.zip -y -oC:\Windows\Resources\Themes

#Añade FFMPEG a las variables para los programas que lo necesitan
Write-Host "Se añade la ruta de FFMPEG a las variables" -ForegroundColor Black -BackgroundColor White
$NewPath = "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin"
$Target = [System.EnvironmentVariableTarget]::Machine
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ";$NewPath", $Target)

#Copio el perfil de PS5 para PS7
Write-Host "Copio el perfil de PS5 para PS7" -ForegroundColor Black -BackgroundColor White
xcopy $env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 $env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1*

#Borro la carpeta de instances en polymc y hago un symlink para el disco D donde están las instancias de MC
Write-Host "Borro la carpeta de instances en polymc y hago un symlink para el disco D donde están las instancias de MC" -ForegroundColor Black -BackgroundColor White
mkdir $env:Appdata\PolyMC
New-Item -ItemType SymbolicLink -Path "$env:Appdata\PolyMC\instances" -Target "D:\MultiMC\instances"

#Recordatorios MANUAL
Write-Host "Recuerda instalar QTTabBar, importar settings e importar settings para Winaero y Handbrake, ademas aplica el tema de rectify11" -ForegroundColor Black -BackgroundColor White
Start-Process "http://qttabbar.wikidot.com/"

#Creo la tarea de sincronizar musica local con nas MANUAL
Write-Host "Agrega el script sync.cmd en Gpedit>PC config>Windows>Scripts>Apagado" -ForegroundColor Black -BackgroundColor White
gpedit