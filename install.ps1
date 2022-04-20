Write-Host "   _____   _   _                              _____                 _             _   _                "
Write-Host "  / ____| (_) | |                            |_   _|               | |           | | | |               "
Write-Host " | |       _  | |__     ___   _ __   ______    | |    _ __    ___  | |_    __ _  | | | |   ___   _ __  "
Write-Host " | |      | | | '_ \   / _ \ | '__| |______|   | |   | '_ \  / __| | __|  / _` | | | | |  / _ \ | '__| "
Write-Host " | |____  | | | |_) | |  __/ | |              _| |_  | | | | \__ \ | |_  | (_| | | | | | |  __/ | |    "
Write-Host "  \_____| |_| |_.__/   \___| |_|             |_____| |_| |_| |___/  \__|  \__,_| |_| |_|  \___| |_|    "

pause


#Instalar nuget para poder instalar XAML
Install-PackageProvider -Name NuGet -Force

#Registro el repositorio de nuget para poder instalar XAML
Register-PackageSource -Name Nuget -Location https://www.nuget.org/api/v2 -ProviderName NuGet

#Instalar otra dependencia para winget
Install-Package Microsoft.UI.Xaml -Force

#Instalar VCLibs para poder instalar winget
Invoke-WebRequest -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -OutFile "$env:TEMP\vclibs.appx"
Add-AppxPackage "$env:TEMP\vclibs.appx"

#Instalar Winget
Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/v1.2.10271/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "$env:TEMP\WinGet.msixbundle"
Start-Sleep 120
Add-AppxPackage "$env:TEMP\WinGet.msixbundle"

#Instalo powershell 7
winget install Microsoft.Powershell --force --accept-package-agreements --accept-source-agreements

#Recargo las variables de entorno para que PS reconozca PS7
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

#Abro PW7
pwsh

# Se habilita la instalacion de scripts externos

Set-ExecutionPolicy AllSigned -Force
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Opcion util en choco
choco feature enable -n=useRememberedArgumentsForUpgrades

choco install ffmpeg oraclejdk jre8 advanced-ipscanner autohotkey eartrumpet bulk-crap-uninstaller cpu-z.install crystaldiskmark crystaldiskinfo.install discord epicgameslauncher everything file-converter handbrake hwinfo insync irfanview --params '/assoc=2' irfanviewplugins lockhunter msiafterburner notepadplusplus obs-studio parsec qbittorrent sharex steam-client teamviewer winaero-tweaker wiztree zerotier-one k-litecodecpackfull dopamine -y

#Desinstalar apps incluidas
Get-appxpackage Microsoft.Windows.Photos | Remove-appxpackage
Get-AppxPackage Microsoft.ZuneVideo | Remove-AppxPackage
DISM /online /disable-feature /featurename:WindowsMediaPlayer
get-appxpackage Microsoft.ZuneMusic | remove-appxpackage

#Instalar scoop
iwr -useb get.scoop.sh | iex

#Instalar pshazz para hacer terminal mas bonita
scoop install pshazz

#Instalar neofetch
scoop install neofetch

#Instalar git
scoop install git

#Instalar nanazip desde winget
winget install m2team.nanazip

#Añade FFMPEG a las variables para los programas que lo necesitan
$NewPath = "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin"
$Target = [System.EnvironmentVariableTarget]::Machine
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ";$NewPath", $Target)
