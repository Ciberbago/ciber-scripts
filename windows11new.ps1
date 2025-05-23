Start-Transcript -Path "C:\ciberlog.txt"
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
$b = @("extras", "nirsoft", "nonportable", "sysinternals")
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
	"clickpaste"
	"cpu-z"
	"crystaldiskinfo"
	"crystaldiskmark"
	"curl"
	"dark"
	"ddu"
	"dotnet-sdk"
	"dotnet6-sdk"
	"everything"
	"ffmpeg"
	"firefox"
	"hwinfo"
	"innounp"
	"iperf3"
	"lanspeedtest"
	"lockhunter"
	"losslesscut"
	"macrorit-partition-expert"
	"neatdownloadmanager"
	"netbscanner"
	"patchcleaner"
	"picotorrent"
	"powertoys"
	"pwsh"
	"sfsu"
	"sharex"
	"speedtest-cli"
	"sudo"
	"tailscale"
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
	"ddu"
	"discord"
	"gpu-z"
	"handbrake"
	"icaros-np"
	"office-365-apps-minimal-np"
	"wireguard-np"
)
$appsTrabajo = @(
	"azcopy"
	"googlechrome"
	"office-365-minimal-apps-np"
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
$casa = @("insync",	"goggalaxy", "anydesk.install", "teamviewer")
$trabajo = @("PowerBi","anydesk.install", "teamviewer")
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
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/config/autohotkey.ahk" -OutFile "$env:USERPROFILE\Documents\autohotkey.ahk"

#Desactivo sticky keys
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "506"
#Activo las extensiones de los archivos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type Dword -Value "0"
#Activo los archivos ocultos
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type Dword -Value "1"
#Desactivo el grabar juegos con la app de xbox (error ms-gamingoverlay)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type Dword -Value "0"
#Se muestran mensajes al estar actualizando
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "verbosestatus" -Value "1"

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
#Mejoro el perfil de PS5
Write-Host "Desinstala las optional features" -ForegroundColor Black -BackgroundColor White
& cmd /c start ms-settings:optionalfeatures

Write-Host "Decarga drivers y ponlos en modo minimal" -ForegroundColor Black -BackgroundColor White
Stop-Transcript
