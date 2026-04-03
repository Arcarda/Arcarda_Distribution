# Arcarda Mod Sync Tool (Production)
# Ensures your mods folder is synchronized with the latest Arcarda Distribution repository.

$RemoteRepo = "https://github.com/Arcarda/Arcarda_Distribution.git"
$ModsFolder = ".\mods"

Write-Host "Updating Arcarda Mod Suite..." -ForegroundColor Cyan

# 1. Check for Git
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "CRITICAL: Git is not installed. Please install Git to sync mods." -ForegroundColor Red
    pause
    exit
}

# 2. Check for Git LFS
if (!(git lfs version 2>$null)) {
    Write-Host "WARNING: Git LFS (Large File Storage) is not installed. Mod binaries will not download correctly." -ForegroundColor Yellow
    Write-Host "Please install Git LFS from https://git-lfs.github.com/ and run 'git lfs install'." -ForegroundColor Yellow
    pause
    exit
}

# 3. Pull latest changes
Write-Host "Pulling latest updates from Arcarda Distribution..." -ForegroundColor Green
git pull origin main

# 4. Success check
if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Mod suite is up to date!" -ForegroundColor Cyan
    $manifest = Get-Content .\manifest.json | ConvertFrom-Json
    Write-Host "Active Version: $($manifest.version)" -ForegroundColor Green
    Write-Host "Last Updated: $($manifest.updated_at)" -ForegroundColor Green
} else {
    Write-Host "ERROR: Sync failed. Please check your internet connection or repository permissions." -ForegroundColor Red
}

pause
