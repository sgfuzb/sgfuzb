# https://medium.com/itmthoughts/installing-docker-on-windows-server-2016-3b395024fc29

# https://docs.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/deploy-containers-on-server

# Enable nested virtualisation on host
Set-VMProcessor MEHSOFTWIRE -ExposeVirtualizationExtensions $true

# Install docker provider
Install-Module DockerMsftProvider -Force
(Install-WindowsFeature Containers).RestartNeeded
#Restart-Computer -Force
Install-Package Docker -ProviderName DockerMsftProvider –Force
Update-Module DockerMsftProvider

# not sure if needed
# https://docs.microsoft.com/en-us/windows/wsl/install-win10
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

# Pull images
docker pull mcr.microsoft.com/windows/servercore:1607
docker image pull mcr.microsoft.com/windows/servercore:ltsc2019
docker image pull mcr.microsoft.com/windows/nanoserver:1809
docker pull mcr.microsoft.com/windows/servercore:20H2
docker run -it docker/surprise
docker run --rm mcr.microsoft.com/dotnet/framework/samples:dotnetapp

# no worky
# docker pull microsoft/windowsservercore
# docker pull microsoft/nanoserver
# docker run -it hello-world powershell 
# docker pull ubuntu:latest

#List
docker ps
docker images