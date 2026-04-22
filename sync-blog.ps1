<#
.SYNOPSIS
    Syncs published blog posts from the Obsidian vault to the Hugo site.

.DESCRIPTION
    Scans the Blog/ folder (root only, not Drafts/) for markdown files with
    status: published in frontmatter. Converts Obsidian conventions to Hugo:
      - Remaps frontmatter (published → date, strips vault-only fields)
      - Converts wikilinks to plain text
      - Removes vault-only footers (See also, Vault Connections)
      - Generates URL-friendly slugs from filenames
    
    Existing Hugo posts are overwritten. Posts removed from the vault source
    are deleted from Hugo. Drafts/ is always ignored.

.EXAMPLE
    .\sync-blog.ps1
    .\sync-blog.ps1 -WhatIf
    .\sync-blog.ps1 -Verbose
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$VaultBlogDir = "C:\Users\alexse\iCloudDrive\iCloud~md~obsidian\Alex\Blog"
$HugoPostsDir = Join-Path $PSScriptRoot "content\posts"
# Vault source can also be overridden: .\sync-blog.ps1 -VaultPath "C:\path\to\vault\Blog"

# --- Helpers ---
function ConvertTo-Slug {
    param([string]$Name)
    $slug = $Name -replace ' – Alex Seward$', ''  # strip author suffix
    $slug = $slug.ToLower()
    $slug = $slug -replace '[^a-z0-9\s-]', ''     # strip special chars
    $slug = $slug -replace '\s+', '-'              # spaces to hyphens
    $slug = $slug -replace '-+', '-'               # collapse hyphens
    $slug = $slug.Trim('-')
    return $slug
}

function Convert-ObsidianToHugo {
    param([string]$Content)

    # Strip wikilinks: [[target|display]] → display, [[target]] → target
    $Content = $Content -replace '\[\[([^\]|]+)\|([^\]]+)\]\]', '$2'
    $Content = $Content -replace '\[\[([^\]]+)\]\]', '$1'

    return $Content
}

function Parse-Frontmatter {
    param([string]$Raw)

    if ($Raw -notmatch '(?s)^---\r?\n(.+?)\r?\n---\r?\n(.*)$') {
        return $null
    }

    $fm = $Matches[1]
    $body = $Matches[2]

    # Extract fields
    $title     = if ($fm -match 'title:\s*"([^"]+)"') { $Matches[1] } else { $null }
    $published = if ($fm -match 'published:\s*(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { $null }
    $status    = if ($fm -match 'status:\s*(\S+)') { $Matches[1] } else { $null }
    $desc      = if ($fm -match 'description:\s*"([^"]+)"') { $Matches[1] } else { $null }

    # Extract tags (excluding 'blog')
    $tags = @()
    if ($fm -match '(?s)tags:\s*\n((?:\s+-\s+.+\n?)+)') {
        $Matches[1] -split "`n" | ForEach-Object {
            if ($_ -match '^\s+-\s+(.+)$') {
                $tag = $Matches[1].Trim()
                if ($tag -ne 'blog') { $tags += $tag }
            }
        }
    }

    return @{
        Title       = $title
        Date        = $published
        Status      = $status
        Description = $desc
        Tags        = $tags
        Body        = $body
    }
}

function Clean-Body {
    param([string]$Body, [string]$Title)

    # Remove duplicate H1 heading matching the title
    if ($Title) {
        $Body = $Body -replace "(?m)^#\s+$([regex]::Escape($Title))\s*$", ""
    }

    # Remove vault-only footers: "See also", "Vault Connections" sections
    $Body = $Body -replace '(?ms)^---\s*\n\s*\*\*See also\*\*:.*$', ''
    $Body = $Body -replace '(?ms)^## Vault Connections\s*\n.*$', ''

    return $Body.Trim()
}

function Build-HugoFrontmatter {
    param($Parsed)

    $lines = @("---")
    $lines += "title: `"$($Parsed.Title)`""
    if ($Parsed.Date) { $lines += "date: $($Parsed.Date)" }
    $lines += "author: `"Alex Seward`""
    if ($Parsed.Description) { $lines += "summary: `"$($Parsed.Description)`"" }
    if ($Parsed.Tags.Count -gt 0) {
        $lines += "tags:"
        foreach ($t in $Parsed.Tags) { $lines += "  - $t" }
    }
    $lines += "---"

    return ($lines -join "`n")
}

# --- Main ---
Write-Host ""
Write-Host "Blog Sync: Vault -> Hugo" -ForegroundColor Cyan
Write-Host "Source: $VaultBlogDir"
Write-Host "Target: $HugoPostsDir"
Write-Host ""

# Ensure target dir exists
if (-not (Test-Path $HugoPostsDir)) {
    New-Item -ItemType Directory -Path $HugoPostsDir -Force | Out-Null
}

# Get source files (root only — skip Drafts/, Blog Index, Intellectual Arc)
$skipFiles = @('Blog Index.md', 'Intellectual Arc.md')
$sourceFiles = Get-ChildItem -Path $VaultBlogDir -Filter "*.md" -File |
    Where-Object { $_.Name -notin $skipFiles }

$synced = @()
$skipped = @()

foreach ($file in $sourceFiles) {
    $raw = Get-Content $file.FullName -Raw -Encoding UTF8
    $parsed = Parse-Frontmatter $raw

    if (-not $parsed) {
        $skipped += "$($file.Name) (no frontmatter)"
        continue
    }

    if ($parsed.Status -ne 'published') {
        $skipped += "$($file.Name) (status: $($parsed.Status))"
        continue
    }

    if (-not $parsed.Title -or -not $parsed.Date) {
        $skipped += "$($file.Name) (missing title or date)"
        continue
    }

    $slug = ConvertTo-Slug $file.BaseName
    $destPath = Join-Path $HugoPostsDir "$slug.md"

    $body = Convert-ObsidianToHugo $parsed.Body
    $body = Clean-Body $body $parsed.Title
    $hugo_fm = Build-HugoFrontmatter $parsed
    $output = "$hugo_fm`n`n$body`n"

    if ($PSCmdlet.ShouldProcess($destPath, "Write post '$($parsed.Title)'")) {
        [System.IO.File]::WriteAllText($destPath, $output, [System.Text.UTF8Encoding]::new($false))
    }

    $synced += [PSCustomObject]@{ Slug = $slug; Title = $parsed.Title; Date = $parsed.Date }
}

# Clean up Hugo posts that no longer have a vault source
$validSlugs = $sourceFiles | ForEach-Object { ConvertTo-Slug $_.BaseName }
$existing = Get-ChildItem -Path $HugoPostsDir -Filter "*.md" -File
$removed = @()

foreach ($f in $existing) {
    $slug = $f.BaseName
    if ($slug -notin $validSlugs) {
        if ($PSCmdlet.ShouldProcess($f.FullName, "Remove orphaned post")) {
            Remove-Item $f.FullName
        }
        $removed += $slug
    }
}

# --- Report ---
Write-Host "Synced: $($synced.Count) posts" -ForegroundColor Green
$synced | Sort-Object Date | ForEach-Object {
    Write-Host "  $($_.Date)  $($_.Title)" -ForegroundColor Gray
}

if ($skipped.Count -gt 0) {
    Write-Host "`nSkipped: $($skipped.Count)" -ForegroundColor Yellow
    $skipped | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkYellow }
}

if ($removed.Count -gt 0) {
    Write-Host "`nRemoved: $($removed.Count) orphaned posts" -ForegroundColor Red
    $removed | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkRed }
}

Write-Host ""
