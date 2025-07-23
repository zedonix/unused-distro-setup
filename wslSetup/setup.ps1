# Requires admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Host "Run this script as Administrator." -ForegroundColor Red
  exit 1
}

# Function to install winget if missing
function Ensure-Winget {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget not found. Attempting to install..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
    Add-AppxPackage "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
  } else {
    Write-Host "Winget is already installed." -ForegroundColor Green
  }
}

# Function to install packages via winget
function Install-Packages {
  $packages = @(
    @{ Id = "Git.Git"; Name = "Git" },
    @{ Id = "Microsoft.WindowsTerminal"; Name = "Windows Terminal" },
    @{ Id = "curl"; Name = "curl" },
    @{ Id = "GnuWin32.Wget"; Name = "wget" }
    @{ Id = "Mozilla.Firefox"; Name = "Firefox" },
    @{ Id = "Microsoft.PowerToys"; Name = "PowerToys" }
  )

  foreach ($pkg in $packages) {
    Write-Host "Installing $($pkg.Name)..." -ForegroundColor Cyan
    winget install --id $($pkg.Id) -e --silent
  }
}

# Function to install Iosevka Term Nerd Font
function Install-IosevkaFont {
  $url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip"
  $zipPath = "$env:TEMP\IosevkaTerm.zip"
  $extractPath = "$env:TEMP\IosevkaTerm"

  Write-Host "Downloading Iosevka Term Nerd Font..." -ForegroundColor Cyan
  Invoke-WebRequest -Uri $url -OutFile $zipPath
  Expand-Archive $zipPath -DestinationPath $extractPath -Force

  Write-Host "Installing fonts..." -ForegroundColor Cyan
  $fonts = Get-ChildItem -Path $extractPath -Filter *.ttf
  foreach ($font in $fonts) {
    Copy-Item $font.FullName -Destination "$env:WINDIR\Fonts"
    $name = $font.Name
    Write-Host "Installed font: $name"
  }
}

# Function to enable and install WSL2
function Install-WSL2 {
  Write-Host "Enabling WSL and Virtual Machine Platform..." -ForegroundColor Cyan
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

  Write-Host "Installing WSL2 kernel..." -ForegroundColor Cyan
  wsl --install --no-distribution

  Write-Host "Setting WSL2 as default version..." -ForegroundColor Cyan
  wsl --set-default-version 2
}

# Execute the functions
Ensure-Winget
Install-Packages
Install-IosevkaFont
Install-WSL2

Write-Host "`nAll tasks completed successfully." -ForegroundColor Green
