param(
  [string]$RepoPath = "D:\Pet finder world website",
  [string]$Message = ""
)

# --- Helpers ---
function Run($cmd) {
  Write-Host "› $cmd" -ForegroundColor Cyan
  iex $cmd
  if ($LASTEXITCODE -ne 0) { throw "Command failed: $cmd" }
}

# --- 1) Go to repo folder ---
Set-Location -Path $RepoPath

# --- 2) First-time setup (if needed) ---
if (-not (Test-Path ".git")) {
  Write-Host "No .git found — initializing repo..." -ForegroundColor Yellow
  Run 'git init'
  # Set main branch
  Run 'git branch -M main'
  # Add remote (change if your remote name is different)
  Run 'git remote add origin https://github.com/InfectedSaint/petfinderworld.git'
}

# --- 3) Create a minimal .gitignore if missing (safe to keep repo clean) ---
if (-not (Test-Path ".gitignore")) {
  @"
# OS clutter
Thumbs.db
.DS_Store

# temp / backups
*.tmp
*.bak

# optional: publish artifacts (uncomment if you ever put build output here)
# publish/
"@ | Out-File -Encoding utf8 .gitignore
}

# --- 4) Ensure your identity is set (one-time) ---
try { git config user.name | Out-Null } catch { }
if (-not (git config user.name)) {
  Run 'git config user.name "John Comalander"'
}
try { git config user.email | Out-Null } catch { }
if (-not (git config user.email)) {
  Run 'git config user.email "you@example.com"'
}

# --- 5) Fetch/pull latest (if remote exists) ---
# Ignore errors if repo has no upstream yet
try {
  Run 'git fetch origin'
  Run 'git pull --rebase origin main'
} catch {
  Write-Host "Skipping pull (probably first push)..." -ForegroundColor DarkYellow
}

# --- 6) Stage, commit (if changes), push ---
Run 'git add -A'

# If no message supplied, make a timestamped one
if ([string]::IsNullOrWhiteSpace($Message)) {
  $Message = "Site update: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
}

# Skip empty commit
$hasChanges = (git status --porcelain) -ne $null -and (git status --porcelain).Length -gt 0
if ($hasChanges) {
  Run "git commit -m `"$Message`""
  Run 'git push -u origin main'
  Write-Host "✅ Pushed to GitHub: InfectedSaint/petfinderworld" -ForegroundColor Green
} else {
  Write-Host "ℹ️ No changes to commit." -ForegroundColor Yellow
}
