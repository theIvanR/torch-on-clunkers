param(
    [string]$RepoPath = "."
)

# Go to target directory
Set-Location $RepoPath

# Check if we're inside a git repo
if (-not (Test-Path ".git")) {
    Write-Host "Not a git repository: $RepoPath" -ForegroundColor Red
    exit 1
}

# Check if there are any changes
$changes = git status --porcelain

if (-not $changes) {
    Write-Host "Nothing to sync" -ForegroundColor Yellow
    exit 0
}

# Stage changes
git add .

# Commit with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "update $timestamp"

# Push
git push

Write-Host "Synced successfully at $timestamp" -ForegroundColor Green