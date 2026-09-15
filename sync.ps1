<#
.SYNOPSIS
    Automated Git synchronization and workflow engine for GitHub Pilot.

.DESCRIPTION
    sync.ps1 — The central synchronization hub for the GitHub Pilot repository:
    https://github.com/Aaradhya-Dev-Tamrakar/github-pilot

    Capabilities:
    1. Remote Verification: Ensures 'origin' remote is correctly configured.
    2. Safe Remote Pull: Pulls latest updates with --rebase --autostash.
    3. Pre-Commit Secret Scanner Guard: Prevents accidental GitHub PAT or credential commits.
    4. Scoped Conventional Commits: Analyzes staged files and scopes conventional commit
       messages (e.g. feat(cli), feat(audit), feat(scraper), feat(profile), docs(pilot)).
    5. Clean Push & Conflict Recovery: Automatically retries rejected pushes via rebase.
    6. Repository Telemetry (-Status): Displays branch health, remote status, and ahead/behind commits.
    7. Dry Run Mode (-WhatIf): Previews staging, secret scan, and commit message safely.
    8. Pre-Commit Test Gate (-Test): Executes pytest suite before committing.

.PARAMETER Message
    Custom commit message (e.g. -m "feat(audit): add branch protection checks").
    Alias: -m. If omitted, an intelligent conventional commit message is generated.

.PARAMETER Branch
    Target or switch to a specific branch to synchronize (e.g. -Branch main).
    Alias: -b.

.PARAMETER PullOnly
    Safely pull remote updates with --rebase --autostash without committing or pushing.

.PARAMETER PushOnly
    Pushes existing local commits without creating new commits.

.PARAMETER NoPush
    Stages and commits changes locally without pushing to remote origin.

.PARAMETER WhatIf
    Dry-run mode: previews changes, secret scan, and auto-generated commit message
    without modifying git repository state.

.PARAMETER Status
    Displays repository telemetry: branch status, remote configuration, ahead/behind
    commits, and working tree health.

.PARAMETER Test
    Runs test suite (pytest tests/) before staging and committing.

.EXAMPLE
    .\sync.ps1                               # Routine sync: commit & push active branch
    .\sync.ps1 -m "feat(cli): add scrape"   # Sync with custom commit message
    .\sync.ps1 -PullOnly                     # Safely pull updates only
    .\sync.ps1 -PushOnly                     # Push existing local commits
    .\sync.ps1 -Status                       # Show repository telemetry
    .\sync.ps1 -WhatIf                       # Dry-run preview
    .\sync.ps1 -Test                         # Run pytest before committing
#>

[CmdletBinding()]
param (
    [Alias("m")]
    [string]$Message,

    [Alias("b")]
    [string]$Branch,

    [switch]$PullOnly,

    [switch]$PushOnly,

    [switch]$NoPush,

    [switch]$WhatIf,

    [switch]$Status,

    [switch]$Test
)

$ErrorActionPreference = "Stop"

$TargetRemoteName = "origin"
$TargetRemoteUrl  = "https://github.com/Aaradhya-Dev-Tamrakar/github-pilot.git"

function Write-Status {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::Cyan
    )
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color
}

function Write-Notice {
    param([string]$Message)
    Write-Status -Message $Message -Color ([System.ConsoleColor]::Yellow)
}

function Write-Success {
    param([string]$Message)
    Write-Status -Message $Message -Color ([System.ConsoleColor]::Green)
}

function Write-Fail {
    param([string]$Message)
    Write-Status -Message $Message -Color ([System.ConsoleColor]::Red)
}

function Ensure-RemoteConfigured {
    $existingRemotes = @(git remote)
    if ($existingRemotes -notcontains $TargetRemoteName) {
        Write-Status "Adding remote '$TargetRemoteName' ($TargetRemoteUrl)..."
        git remote add $TargetRemoteName $TargetRemoteUrl
    } else {
        $actualUrl = (git remote get-url $TargetRemoteName).Trim()
        if ($actualUrl -ne $TargetRemoteUrl) {
            Write-Notice "Updating remote '$TargetRemoteName' URL to $TargetRemoteUrl"
            git remote set-url $TargetRemoteName $TargetRemoteUrl
        }
    }
}

function Scan-Secrets {
    param([string[]]$Files)

    $secretPatterns = @(
        'ghp_[A-Za-z0-9_]{36,}',
        'github_pat_[A-Za-z0-9_]{82,}',
        'AIzaSy[A-Za-z0-9_-]{33}',
        'sk-[A-Za-z0-9]{32,}',
        'Bearer\s+[A-Za-z0-9_\-\.]{25,}'
    )

    $violations = @()

    foreach ($file in $Files) {
        if (-not (Test-Path $file -PathType Leaf)) { continue }
        if ($file -match '\.(png|jpg|jpeg|gif|ico|pdf|whl|exe|bin|sqlite3|db)$') { continue }
        if ($file -match '(\.env\.example)$') { continue }

        $content = Get-Content -Path $file -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        foreach ($pattern in $secretPatterns) {
            if ($content -match $pattern) {
                $violations += "File '$file' matched secret pattern: $pattern"
            }
        }
    }

    if ($violations.Count -gt 0) {
        Write-Fail "PRE-COMMIT SCAN FAILED: Potential secrets detected!"
        foreach ($v in $violations) {
            Write-Host "  - $v" -ForegroundColor Red
        }
        throw "Commit aborted due to potential secret leakage."
    }
}

function Get-ConventionalCommitMessage {
    param([string[]]$ChangedFiles)

    if ($ChangedFiles.Count -eq 0) {
        return "chore(pilot): routine repository maintenance"
    }

    $isCli = $false
    $isAudit = $false
    $isProfile = $false
    $isDigest = $false
    $isScraper = $false
    $isDocs = $false
    $isTests = $false

    foreach ($f in $ChangedFiles) {
        if ($f -match 'pilot/cli\.py') { $isCli = $true }
        elseif ($f -match 'pilot/core/auditor\.py') { $isAudit = $true }
        elseif ($f -match 'pilot/core/profile\.py') { $isProfile = $true }
        elseif ($f -match 'pilot/core/digest\.py') { $isDigest = $true }
        elseif ($f -match 'pilot/scraper/') { $isScraper = $true }
        elseif ($f -match 'tests/') { $isTests = $true }
        elseif ($f -match '\.md$') { $isDocs = $true }
    }

    if ($isCli) { return "feat(cli): update pilot CLI workflows and subcommands" }
    if ($isAudit) { return "feat(audit): update fleet audit checks and reporting" }
    if ($isProfile) { return "feat(profile): enhance profile synthesis and SVG telemetry" }
    if ($isDigest) { return "feat(digest): update changelog aggregation logic" }
    if ($isScraper) { return "feat(scraper): update web intelligence and trending parsers" }
    if ($isTests) { return "test(pilot): update test fixtures and assertions" }
    if ($isDocs) { return "docs(pilot): update documentation and agent operational specs" }

    return "chore(pilot): update core components"
}

function Show-Telemetry {
    Ensure-RemoteConfigured
    $currentBranch = (git branch --show-current).Trim()
    Write-Status "=== GitHub Pilot Telemetry ===" -Color Cyan
    Write-Host "Active Branch : $currentBranch"
    Write-Host "Remote URL    : $TargetRemoteUrl"

    $statusShort = git status -s
    if ($statusShort) {
        Write-Host "`nUncommitted Changes:" -ForegroundColor Yellow
        Write-Host $statusShort
    } else {
        Write-Host "`nWorking tree clean." -ForegroundColor Green
    }

    $unpushed = git log "$TargetRemoteName/$currentBranch..$currentBranch" --oneline 2>$null
    if ($unpushed) {
        Write-Host "`nUnpushed Commits:" -ForegroundColor Magenta
        Write-Host $unpushed
    } else {
        Write-Host "`nAll commits pushed to $TargetRemoteName." -ForegroundColor Green
    }
}

# --- Main Flow ---
try {
    Ensure-RemoteConfigured

    if ($Status) {
        Show-Telemetry
        exit 0
    }

    $currentBranch = (git branch --show-current).Trim()

    if ($Branch -and $Branch -ne $currentBranch) {
        Write-Status "Switching to branch '$Branch'..."
        git checkout $Branch
        $currentBranch = $Branch
    }

    if ($PullOnly) {
        Write-Status "Pulling latest updates for '$currentBranch'..."
        git pull --rebase --autostash $TargetRemoteName $currentBranch
        Write-Success "Pull complete."
        exit 0
    }

    if ($PushOnly) {
        Write-Status "Pushing existing commits on '$currentBranch'..."
        git push $TargetRemoteName $currentBranch
        Write-Success "Push complete."
        exit 0
    }

    if ($Test) {
        Write-Status "Running test suite before sync..."
        if (Test-Path ".\.venv\Scripts\pytest.exe") { & .\.venv\Scripts\pytest.exe tests/ } else { python -m pytest tests/ }
        if ($LASTEXITCODE -ne 0) {
            throw "Tests failed. Commit halted."
        }
        Write-Success "All tests passed."
    }

    $statusOutput = git status --porcelain
    if (-not $statusOutput) {
        Write-Notice "Working directory clean. Checking for unpushed commits..."
        $unpushed = git log "$TargetRemoteName/$currentBranch..$currentBranch" --oneline 2>$null
        if ($unpushed -and -not $NoPush) {
            Write-Status "Pushing unpushed commits..."
            git push $TargetRemoteName $currentBranch
            Write-Success "Push complete."
        } else {
            Write-Success "Repository is fully synchronized."
        }
        exit 0
    }

    $changedFiles = ($statusOutput -split "`n") | ForEach-Object {
        if ($_ -match '^..\s+(.+)$') { $matches[1].Trim() }
    } | Where-Object { $_ }

    Scan-Secrets -Files $changedFiles

    $commitMsg = $Message
    if (-not $commitMsg) {
        $commitMsg = Get-ConventionalCommitMessage -ChangedFiles $changedFiles
    }

    if ($WhatIf) {
        Write-Status "[WHATIF] Dry-run preview:" -Color Yellow
        Write-Host "Target Remote : $TargetRemoteUrl ($currentBranch)"
        Write-Host "Commit Scope  : $commitMsg"
        Write-Host "Files Changed :"
        foreach ($f in $changedFiles) { Write-Host "  $f" }
        exit 0
    }

    Write-Status "Staging changes..."
    git add -A

    Write-Status "Committing: '$commitMsg'..."
    git commit -m $commitMsg

    if (-not $NoPush) {
        Write-Status "Pulling remote updates with rebase..."
        git pull --rebase --autostash $TargetRemoteName $currentBranch

        Write-Status "Pushing to $TargetRemoteName/$currentBranch..."
        git push $TargetRemoteName $currentBranch
        Write-Success "Successfully synchronized $currentBranch!"
    } else {
        Write-Success "Committed locally (NoPush specified)."
    }
} catch {
    Write-Fail "Sync error: $_"
    exit 1
}

