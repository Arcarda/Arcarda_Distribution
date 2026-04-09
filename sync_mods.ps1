# Arcarda Mod Suite Synchronization Script
# For GTNH Modpack Integration

Param(
    [string]$DistRepo = "https://github.com/Arcarda/Arcarda_Distribution.git",
    [string]$Side = "Both", # Valid: Both, Client, Server
    [string]$TargetDir = "", # Path to the instance "mods" folder
    [switch]$IncludeSideloads, # Opt-in to experimental/external mods (TST, SNB)
    [switch]$ForceUpdate
)

$ErrorActionPreference = "Continue" # Allow skipping if file is locked
$MANIFEST_URL = "https://raw.githubusercontent.com/Arcarda/Arcarda_Distribution/main/manifest.json"
$LOCAL_VERSION_FILE = "version.txt"
$LOCAL_LIBS = "libs"

Write-Host "`n--- Arcarda Mod Suite Synchronization ---" -ForegroundColor Cyan
Write-Host "[INIT] Deployment Side: $Side" -ForegroundColor Gray
if ($IncludeSideloads) { Write-Host "[INIT] Sideloading enabled: TST, SNB" -ForegroundColor Yellow }

# Aggressive purge patterns for legacy or conflicting Arcarda mods
$PURGE_PATTERNS = @(
    "*ArcRifts*", 
    "*ArcardaCore*", 
    "*PollutionMod*", 
    "*PollutionMutation*",
    "*GTNH-RoR*", 
    "*JournalsOfArcarda*", 
    "*RecipeExplorer*", 
    "*mekkina-neural-avatar*"
)

function Test-SideMatch($targetSide, $currentSide) {
    return ($currentSide -eq "Both") -or ($targetSide -eq "both") -or ($targetSide -eq $currentSide.ToLower())
}

function Purge-ConflictingMods {
    param($Target)
    if ($Target -and (Test-Path $Target)) {
        Write-Host "[PURGE] Cleaning old Arcarda suite files from $Target..." -ForegroundColor Yellow
        foreach ($pattern in $PURGE_PATTERNS) {
            $oldFiles = Get-ChildItem -Path $Target -Filter $pattern -File
            foreach ($file in $oldFiles) {
                try {
                    Write-Host "[PURGE] Removing $($file.Name)..." -ForegroundColor Gray
                    Remove-Item $file.FullName -Force
                } catch {
                    Write-Host "[WARN] Could not remove $($file.Name). It may be in use." -ForegroundColor Red
                }
            }
        }
    }
}

function Sync-File {
    param($JarName, $Target)
    if ($Target -and (Test-Path $Target)) {
        $localPath = ""
        if (Test-Path "$LOCAL_LIBS\$JarName") {
            $localPath = "$LOCAL_LIBS\$JarName"
        } elseif (Test-Path "NotMine\$JarName") {
            $localPath = "NotMine\$JarName"
        }

        if ($localPath) {
            Write-Host "[DEPLOY] Copying $JarName..." -ForegroundColor Green
            Copy-Item "$localPath" -Destination "$Target"
        } else {
            Write-Host "[WARN] $JarName not found in local sources (libs/NotMine). Skipping." -ForegroundColor Red
        }
    } else {
        Write-Host "[STAGING] $JarName is ready." -ForegroundColor Gray
    }
}

# START SYNC
try {
    $manifest = Get-Content -Raw "manifest.json" | ConvertFrom-Json
    $remoteVersion = $manifest.version
    
    $localVersion = "0.0.0"
    if (Test-Path $LOCAL_VERSION_FILE) {
        $localVersion = Get-Content $LOCAL_VERSION_FILE
    }

    if ($localVersion -ne $remoteVersion -or $ForceUpdate) {
        Write-Host "[SYNC] Processing Update: v$remoteVersion" -ForegroundColor Yellow
        
        # 1. Purge all Arcarda suite mods first to ensure a clean state
        if ($TargetDir) { Purge-ConflictingMods -Target $TargetDir }
        
        # 2. Deploy Core Mods
        foreach ($mod in $manifest.mods) {
            if (Test-SideMatch $mod.side $Side) {
                Sync-File -JarName $mod.jar -Target $TargetDir
            }
        }
        
        # 3. Deploy Sideloads (Optional)
        if ($IncludeSideloads -and $manifest.sideloads) {
            foreach ($mod in $manifest.sideloads) {
                if (Test-SideMatch $mod.side $Side) {
                    Sync-File -JarName $mod.jar -Target $TargetDir
                }
            }
        }
        
        Set-Content -Path $LOCAL_VERSION_FILE -Value $remoteVersion
        Write-Host "[SYNC] Synchronization complete." -ForegroundColor Green
        
        $RP_SOURCE = "$DistRepo\..\Arcarda_Resources.zip"
        if(Test-Path "Arcarda_Resources.zip") {
            $rpTarget = "$TargetDir\..\resourcepacks"
            if(!(Test-Path $rpTarget)) { New-Item -ItemType Directory -Path $rpTarget | Out-Null }
            Copy-Item "Arcarda_Resources.zip" "$rpTarget\Arcarda_Resources.zip" -Force
            Write-Host "[DEPLOY] Pushed Arcarda_Resources.zip clientside." -ForegroundColor Green
        }
    } else {
        Write-Host "[SYNC] Local suite is up to date (v$localVersion)." -ForegroundColor Green
    }
} catch {
   Write-Host "[SYNC] Error: $_" -ForegroundColor DarkRed
}

Write-Host "--- Done ---`n" -ForegroundColor Cyan
