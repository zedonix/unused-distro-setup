# Requires admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Write-Host "Run this script as Administrator." -ForegroundColor Red
  exit 1
}

# Global static path to local repo
[string]$RepoPath = "$env:USERPROFILE\Downloads\wslSetup-main"

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
    @{ Id = "Mozilla.Firefox"; Name = "Firefox" },
    @{ Id = "Microsoft.PowerToys"; Name = "PowerToys" },
    @{ Id = "dandavison.delta"; Name = "git-delta" },
    @{ Id = "jftuga.less"; Name = "less (modern)" }
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
    Write-Host "Installed font: $($font.Name)"
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

# Function to copy user.js to Firefox profile
function Setup-FirefoxUserJS {
  $firefoxProfilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
  $profileDirs = Get-ChildItem -Path $firefoxProfilesPath -Directory | Where-Object { $_.Name -like "*.default-release" }

  if ($profileDirs.Count -eq 0) {
    Write-Host "No default Firefox profile found in $firefoxProfilesPath" -ForegroundColor Red
    return
  }

  $userJsSource = Join-Path $RepoPath "user.js"
  $userJsTarget = Join-Path $profileDirs[0].FullName "user.js"

  if (-not (Test-Path $userJsSource)) {
    Write-Host "user.js not found in local repo." -ForegroundColor Red
    return
  }

  Copy-Item -Path $userJsSource -Destination $userJsTarget -Force
  Write-Host "user.js copied to: $userJsTarget" -ForegroundColor Green
}

# Function to copy policies.json to Firefox distribution directory
function Setup-FirefoxPolicies {
  $policySource = Join-Path $RepoPath "policies.json"
  $firefoxDistDir = "C:\Program Files\Mozilla Firefox\distribution"
  $policyTarget = Join-Path $firefoxDistDir "policies.json"

  if (-not (Test-Path $policySource)) {
    Write-Host "policies.json not found at $policySource" -ForegroundColor Red
    return
  }

  if (-not (Test-Path $firefoxDistDir)) {
    Write-Host "Firefox distribution directory not found: $firefoxDistDir" -ForegroundColor Red
    return
  }

  try {
    Copy-Item -Path $policySource -Destination $policyTarget -Force
    Write-Host "policies.json copied to: $policyTarget" -ForegroundColor Green
  } catch {
    Write-Host "`nAccess denied. You must run PowerShell as Administrator to modify:" -ForegroundColor Yellow
    Write-Host "`t$policyTarget" -ForegroundColor Red
    Write-Host "`nPlease copy the file manually or rerun with admin rights." -ForegroundColor Gray
  }
}

# Function to copy .gitconfig
function Setup-GitConfig {
  $gitConfigSource = Join-Path $RepoPath ".gitconfig"
  $gitConfigTarget = Join-Path $env:USERPROFILE ".gitconfig"

  if (-not (Test-Path $gitConfigSource)) {
    Write-Host ".gitconfig not found at $gitConfigSource" -ForegroundColor Red
    return
  }

  Copy-Item -Path $gitConfigSource -Destination $gitConfigTarget -Force
  Write-Host ".gitconfig copied to: $gitConfigTarget" -ForegroundColor Green
}

# ==== Execute ====

Ensure-Winget
Install-Packages
Setup-GitConfig
Install-IosevkaFont

# Launch Firefox once to ensure profile gets created
Start-Process "firefox" -Wait

Setup-FirefoxUserJS
Setup-FirefoxPolicies
Install-WSL2

# Windows settings Tweaks
# Set mouse acceleration off
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"

# Enable only "Smooth edges of screen fonts"
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-ItemProperty -Path $regPath -Name VisualFXSetting -Value 2
$fxPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $fxPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))  # disables most effects except smooth font edges

# Enable long path support:
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWord -Force

Write-Host "`nAll tasks completed successfully." -ForegroundColor Green
