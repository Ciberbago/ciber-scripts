Write-Host "   _____   _   _                              _____                 _             _   _                "
Write-Host "  / ____| (_) | |                            |_   _|               | |           | | | |               "
Write-Host " | |       _  | |__     ___   _ __   ______    | |    _ __    ___  | |_    __ _  | | | |   ___   _ __  "
Write-Host " | |      | | | '_ \   / _ \ | '__| |______|   | |   | '_ \  / __| | __|  / _` | | | | |  / _ \ | '__| "
Write-Host " | |____  | | | |_) | |  __/ | |              _| |_  | | | | \__ \ | |_  | (_| | | | | | |  __/ | |    "
Write-Host "  \_____| |_| |_.__/   \___| |_|             |_____| |_| |_| |___/  \__|  \__,_| |_| |_|  \___| |_|    "

pause


#Instalar nuget para poder instalar XAML
Write-Host "Instalando Nuget" -ForegroundColor Black -BackgroundColor White
Install-PackageProvider -Name NuGet -Force

#Registro el repositorio de nuget para poder instalar XAML
Write-Host "Instalando proveedor Nuget" -ForegroundColor Black -BackgroundColor White
Register-PackageSource -Name Nuget -Location https://www.nuget.org/api/v2 -ProviderName NuGet

#Instalar otra dependencia para winget
Write-Host "Instalando XAML" -ForegroundColor Black -BackgroundColor White
Install-Package Microsoft.UI.Xaml -Force

#Instalar VCLibs para poder instalar winget
Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile "$env:TEMP\vclibs.appx"
Write-Host "Instalando VCLibs" -ForegroundColor Black -BackgroundColor White
Add-AppxPackage "$env:TEMP\vclibs.appx"

#Instalar Winget
Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "$env:TEMP\WinGet.msixbundle"
Start-Sleep 120
Write-Host "Instalando Winget" -ForegroundColor Black -BackgroundColor White
Add-AppxPackage "$env:TEMP\WinGet.msixbundle"

#Instalo powershell 7
Write-Host "Instalando PS7" -ForegroundColor Black -BackgroundColor White
winget install Microsoft.Powershell --force --accept-package-agreements --accept-source-agreements

#Recargo las variables de entorno para que PS reconozca PS7
Write-Host "Recargando variables de entorno" -ForegroundColor Black -BackgroundColor White
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

#Instalar scoop
Write-Host "Instalando scoop" -ForegroundColor Black -BackgroundColor White
iwr -useb get.scoop.sh -outfile "$env:TEMP\install.ps1"
cd $env:TEMP
set-executionpolicy remotesigned
.\install.ps1 -RunAsAdmin
cd ~

#Instalar git
Write-Host "Instalando git" -ForegroundColor Black -BackgroundColor White
scoop install git

#Instalar pshazz para hacer terminal mas bonita
Write-Host "Instalando pshazz" -ForegroundColor Black -BackgroundColor White
scoop install pshazz

#Instalar neofetch
Write-Host "Instalando neofetch" -ForegroundColor Black -BackgroundColor White
scoop install neofetch

# Se habilita la instalacion de scripts externos
Write-Host "Instalando Chocolatey" -ForegroundColor Black -BackgroundColor White
Set-ExecutionPolicy AllSigned -Force
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Opcion util en choco
Write-Host "Instalando Programas con choco" -ForegroundColor Black -BackgroundColor White
choco feature enable -n=useRememberedArgumentsForUpgrades

choco install ffmpeg oraclejdk jre8 advanced-ipscanner autohotkey eartrumpet bulk-crap-uninstaller cpu-z.install crystaldiskmark crystaldiskinfo.install discord epicgameslauncher everything file-converter handbrake hwinfo insync irfanview --params '/assoc=2' irfanviewplugins lockhunter msiafterburner notepadplusplus obs-studio parsec qbittorrent sharex steam-client teamviewer winaero-tweaker wiztree zerotier-one k-litecodecpackfull dopamine -y

#Instalar nanazip desde winget
Write-Host "Instalando nanazip con winget" -ForegroundColor Black -BackgroundColor White
winget install m2team.nanazip

#Desinstalar apps incluidas
Write-Host "Desinstalando apps incluidas con windows" -ForegroundColor Black -BackgroundColor White
Get-appxpackage Microsoft.Windows.Photos | Remove-appxpackage
Get-AppxPackage Microsoft.ZuneVideo | Remove-AppxPackage
DISM /online /disable-feature /featurename:WindowsMediaPlayer
get-appxpackage Microsoft.ZuneMusic | remove-appxpackage

#Añade FFMPEG a las variables para los programas que lo necesitan
Write-Host "Se añade la ruta de FFMPEG a las variables" -ForegroundColor Black -BackgroundColor White
$NewPath = "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin"
$Target = [System.EnvironmentVariableTarget]::Machine
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ";$NewPath", $Target)

#Windows Update
Write-Host "Instalo windows update" -ForegroundColor Black -BackgroundColor White
Install-Module PSWindowsUpdate -Force
Set-executionpolicy remotesigned
Write-Host "Añado microsoft updates a los repo" -ForegroundColor Black -BackgroundColor White
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
Write-Host "Actualizo windows update" -ForegroundColor Black -BackgroundColor White
Get-WindowsUpdate
Write-Host "Instalo updates" -ForegroundColor Black -BackgroundColor White
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
