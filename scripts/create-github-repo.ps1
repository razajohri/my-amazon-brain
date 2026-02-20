# Create GitHub repo and push this project
# Requires: GITHUB_TOKEN env var (with repo scope), or run and paste when prompted
# Get a token: https://github.com/settings/tokens -> Generate new (classic) -> repo scope

$ErrorActionPreference = "Stop"
$repoName = "amazon-seller-data-chat"
$repoDesc = "Talk to your Amazon seller data using natural language prompts"

if (-not $env:GITHUB_TOKEN) {
    Write-Host "GitHub Personal Access Token required (scope: repo)."
    Write-Host "Get one: https://github.com/settings/tokens"
    $env:GITHUB_TOKEN = Read-Host "Paste your token (or set GITHUB_TOKEN env var and re-run)"
}

$headers = @{
    "Authorization" = "Bearer $($env:GITHUB_TOKEN)"
    "Accept"        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}
$body = @{
    name        = $repoName
    description = $repoDesc
    private     = $false
    auto_init   = $false
} | ConvertTo-Json

Write-Host "Creating GitHub repo '$repoName'..."
$repoUrl = $null
try {
    $resp = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $body -ContentType "application/json"
    $cloneUrl = $resp.clone_url
    $repoUrl = $resp.html_url
    Write-Host "Repo created: $repoUrl"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 422) {
        Write-Host "Repo '$repoName' may already exist. Using existing repo."
        $user = (Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers)
        $cloneUrl = "https://github.com/$($user.login)/$repoName.git"
        $repoUrl = "https://github.com/$($user.login)/$repoName"
    } else { throw }
}

$root = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $root ".git"))) {
    Write-Host "No .git in project root. Run this from repo root or fix path."
    exit 1
}
Set-Location $root

$pushUrl = $cloneUrl -replace "https://", "https://$($env:GITHUB_TOKEN)@"
$remote = (git remote get-url origin 2>$null)
if (-not $remote) {
    git remote add origin $pushUrl
    Write-Host "Remote 'origin' added."
} else {
    git remote set-url origin $pushUrl
    Write-Host "Remote 'origin' updated."
}
git branch -M main
Write-Host "Pushing to origin main..."
git push -u origin main
git remote set-url origin $cloneUrl
Write-Host "Remote URL cleared of token (safe to store)."
Write-Host "Done. Repo: $repoUrl"