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

    Existing Hugo posts with matching slugs are overwritten. Posts removed from
    the vault source are only deleted from Hugo when -Prune is provided.
    Drafts/ is always ignored.

.EXAMPLE
    .\sync-blog.ps1
    .\sync-blog.ps1 -WhatIf
    .\sync-blog.ps1 -Verbose
    .\sync-blog.ps1 -VaultPath "C:\path\to\vault\Blog" -Prune
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$VaultPath = $env:BLOG_VAULT_PATH,
    [switch]$Prune,
    [switch]$SkipThinkingRefresh
)

$ErrorActionPreference = 'Stop'

# --- Configuration ---
if (-not $VaultPath) {
    throw "Set BLOG_VAULT_PATH or pass -VaultPath with the path to your Obsidian Blog folder."
}

$VaultBlogDir = $VaultPath
$HugoPostsDir = Join-Path $PSScriptRoot "content\posts"
# Vault source can be set with BLOG_VAULT_PATH or overridden with -VaultPath.

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

function Get-FrontmatterValue {
    param([string]$Frontmatter, [string]$Key)

    $pattern = "(?m)^$([regex]::Escape($Key)):\s*(.+?)\s*$"
    if ($Frontmatter -notmatch $pattern) {
        return $null
    }

    $value = $Matches[1].Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    return $value
}

function Get-FrontmatterTags {
    param([string]$Frontmatter)

    $tags = @()
    $inline = Get-FrontmatterValue $Frontmatter "tags"

    if ($inline -and $inline.StartsWith("[") -and $inline.EndsWith("]")) {
        $inline.Trim("[]") -split "," | ForEach-Object {
            $tag = $_.Trim().Trim('"').Trim("'")
            if ($tag -and $tag -ne 'blog') { $tags += $tag }
        }
    }
    elseif ($Frontmatter -match '(?ms)^tags:\s*\r?\n((?:\s+-\s+.+\r?\n?)+)') {
        $Matches[1] -split "\r?\n" | ForEach-Object {
            if ($_ -match '^\s+-\s+(.+?)\s*$') {
                $tag = $Matches[1].Trim().Trim('"').Trim("'")
                if ($tag -and $tag -ne 'blog') { $tags += $tag }
            }
        }
    }

    return $tags
}

function Parse-Frontmatter {
    param([string]$Raw)

    if ($Raw -notmatch '(?s)^---\r?\n(.+?)\r?\n---\r?\n(.*)$') {
        return $null
    }

    $fm = $Matches[1]
    $body = $Matches[2]

    $title = Get-FrontmatterValue $fm "title"
    $published = Get-FrontmatterValue $fm "published"
    $status = Get-FrontmatterValue $fm "status"
    $desc = Get-FrontmatterValue $fm "description"
    $section = Get-FrontmatterValue $fm "sectionLabel"
    $featured = (Get-FrontmatterValue $fm "featured") -eq "true"
    $tags = Get-FrontmatterTags $fm

    return @{
        Title       = $title
        Date        = $published
        Status      = $status
        Description = $desc
        Section     = $section
        Featured    = $featured
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

function ConvertTo-YamlString {
    param([string]$Value)

    $quote = [char]39
    if ($null -eq $Value) {
        return "$quote$quote"
    }

    $escaped = $Value -replace $quote, "$quote$quote"
    $escaped = $escaped -replace "`r`n|`n|`r", " "
    return "$quote$escaped$quote"
}

function Build-HugoFrontmatter {
    param($Parsed)

    $lines = @("---")
    $lines += "title: $(ConvertTo-YamlString $Parsed.Title)"
    if ($Parsed.Date) { $lines += "date: $($Parsed.Date)" }
    $lines += "author: $(ConvertTo-YamlString 'Alex Seward')"
    if ($Parsed.Description) { $lines += "summary: $(ConvertTo-YamlString $Parsed.Description)" }
    if ($Parsed.Featured) { $lines += "featured: true" }
    if ($Parsed.Section) { $lines += "sectionLabel: $(ConvertTo-YamlString $Parsed.Section)" }
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

$removed = @()

if ($Prune) {
    # Clean up Hugo posts that no longer have a synced published source.
    $validSlugs = $synced | ForEach-Object { $_.Slug }
    $existing = Get-ChildItem -Path $HugoPostsDir -Filter "*.md" -File

    foreach ($f in $existing) {
        $slug = $f.BaseName
        if ($slug -notin $validSlugs) {
            if ($PSCmdlet.ShouldProcess($f.FullName, "Remove orphaned post")) {
                Remove-Item $f.FullName
            }
            $removed += $slug
        }
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

if ($Prune -and $removed.Count -gt 0) {
    Write-Host "`nRemoved: $($removed.Count) orphaned posts" -ForegroundColor Red
    $removed | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkRed }
}
elseif (-not $Prune) {
    Write-Host "`nPrune disabled: no existing Hugo posts were deleted. Run with -Prune to remove orphaned posts." -ForegroundColor DarkGray
}

if (-not $SkipThinkingRefresh) {
    $thinkingScript = Join-Path $PSScriptRoot "sync-thinking.ps1"
    if (Test-Path $thinkingScript) {
        $vaultRoot = Split-Path $VaultBlogDir -Parent
        Write-Host "`nRefreshing Thinking page data..." -ForegroundColor Cyan
        & $thinkingScript -VaultPath $vaultRoot
    }
}

Write-Host ""
