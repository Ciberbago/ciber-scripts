#Instalo SSH
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

#Instalo powershell 7
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://github.com/PowerShell/PowerShell/releases/download/v7.2.1/PowerShell-7.2.1-win-x64.msi","$env:temp\thost.msi")

#Instalo utileria para habilitar PWSH en ssh
Install-Module -Name Microsoft.PowerShell.RemotingTools -Force

#Abro PW7
pwsh

#Habilito pwsh en ssh
Enable-SSHRemoting -Verbose

#Reinicio el servicio de SSH
Restart-Service -Name sshd

# Se habilita la instalacion de scripts externos

Set-ExecutionPolicy AllSigned -Force
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Opcion util en choco
choco feature enable -n=useRememberedArgumentsForUpgrades

choco install paint.net openjdk jre8 advanced-ipscanner autohotkey eartrumpet bulk-crap-uninstaller cpu-z.install crystaldiskmark crystaldiskinfo.install discord epicgameslauncher everything file-converter handbrake hwinfo insync irfanview --params '/assoc=2' irfanviewplugins lockhunter msiafterburner notepadplusplus obs-studio parsec qbittorrent sharex steam-client teamviewer winaero-tweaker wiztree zerotier-one k-litecodecpackfull dopamine -y

Add-AppPackage -path "https://github.com/M2Team/NanaZip/releases/download/1.0-Preview3/40174MouriNaruto.NanaZip_1.0.46.0_gnj4mf6z9tkrc.msixbundle"

#Desinstalar apps incluidas
Get-appxpackage *Microsoft.Windows.Photos* | remove-appxpackage
Get-AppxPackage Microsoft.ZuneVideo | Remove-AppxPackage
DISM /online /disable-feature /featurename:WindowsMediaPlayer
get-appxpackage *Microsoft.ZuneMusic* | remove-appxpackage

#Instalar scoop
iwr -useb get.scoop.sh | iex

#Instalar pshazz para hacer terminal mas bonita
scoop install pshazz

#Instalar neofetch
scoop install neofetch

#Instalar git
scoop install git 
