<#
.SYNOPSIS
    Generates the public "Thinking" page data from Alex's Obsidian vault.

.DESCRIPTION
    Scans safe vault areas using note titles and file metadata only, then writes
    data/thinking.json for Hugo. The script deliberately avoids publishing raw
    note bodies or private excerpts.

.EXAMPLE
    .\sync-thinking.ps1
    .\sync-thinking.ps1 -VaultPath "C:\path\to\vault"
#>

[CmdletBinding()]
param(
    [string]$VaultPath = $env:THINKING_VAULT_PATH,
    [string]$OutputPath = (Join-Path $PSScriptRoot "data\thinking.json"),
    [int]$MaxRecent = 24
)

$ErrorActionPreference = 'Stop'

if (-not $VaultPath) {
    $candidate = Join-Path $HOME "iCloudDrive\iCloud~md~obsidian\Alex"
    if (Test-Path $candidate) {
        $VaultPath = $candidate
    }
    else {
        throw "Set THINKING_VAULT_PATH or pass -VaultPath with the path to the Obsidian vault."
    }
}

if (-not (Test-Path $VaultPath)) {
    throw "Vault path not found: $VaultPath"
}

function Get-RelativePath {
    param([string]$BasePath, [string]$FullPath)
    return $FullPath.Substring($BasePath.TrimEnd('\').Length + 1)
}

function ConvertTo-PublicTitle {
    param([System.IO.FileInfo]$File)

    $title = $File.BaseName -replace '\s+– Alex Seward$', ''
    $title = $title -replace '\s+-\s+Alex Seward$', ''
    $title = $title -replace '\s+', ' '
    return $title.Trim()
}

function Test-IsPublicIndexNote {
    param([string]$RelativePath, [string]$Title)

    if ($RelativePath -like 'Clippings\*') {
        return $false
    }

    $indexTitles = @(
        'Map of Content',
        'Blog Index',
        'Source Material Index',
        'Steelmen Index',
        'Intellectual Arc',
        'Glossary'
    )

    if ($indexTitles -contains $Title) {
        return $true
    }

    return $Title -match '\bIndex$'
}

function Get-NoteKind {
    param([string]$RelativePath)

    if ($RelativePath -like 'Clippings\*') { return 'Reading' }
    if ($RelativePath -like 'Blog\*') { return 'Writing' }
    return 'Thinking'
}

function Get-TopicDefinition {
    return @(
        @{
            Label = 'Agentic AI'
            Match = @('agentic', 'agents', 'agent')
            Summary = 'Agentic AI, tools, prompt engineering, and new working patterns.'
            ClusterTitle = 'AI systems becoming working practice.'
        },
        @{
            Label = 'Second brain'
            Match = @('second brain', 'knowledge', 'map of content', 'vault')
            Summary = 'Personal knowledge management, memory, and AI-supported maintenance.'
            ClusterTitle = 'Personal knowledge becoming a working system.'
        },
        @{
            Label = 'Adoption layer'
            Match = @('adoption', 'capability', 'pilot', 'production', 'impact')
            Summary = 'The organisational gap between AI experiments and repeatable value.'
            ClusterTitle = 'AI adoption meeting organisational capability.'
        },
        @{
            Label = 'Responsible AI'
            Match = @('responsible', 'governance', 'literacy', 'centre of excellence')
            Summary = 'Governance, literacy, and the practices that make AI usable safely.'
            ClusterTitle = 'Responsible AI becoming practical governance.'
        },
        @{
            Label = 'Data architecture'
            Match = @('data', 'architecture', 'rag', 'retrieval')
            Summary = 'Data foundations, architecture, retrieval, and enterprise readiness.'
            ClusterTitle = 'Data foundations shaping AI readiness.'
        },
        @{
            Label = 'Prompting'
            Match = @('prompt', 'prompting')
            Summary = 'The craft of shaping model behaviour through language and context.'
            ClusterTitle = 'Prompting as a practical interface.'
        }
    )
}

function Get-TopicScores {
    param($Notes)

    $definitions = Get-TopicDefinition
    $scores = foreach ($definition in $definitions) {
        $count = 0
        foreach ($note in $Notes) {
            $haystack = "$($note.Title) $($note.RelativePath)".ToLowerInvariant()
            foreach ($term in $definition.Match) {
                if ($haystack.Contains($term)) {
                    $count++
                    break
                }
            }
        }

        [PSCustomObject]@{
            Label = $definition.Label
            Score = $count
            Summary = $definition.Summary
            ClusterTitle = $definition.ClusterTitle
        }
    }

    return $scores | Sort-Object @{ Expression = 'Score'; Descending = $true }, @{ Expression = 'Label'; Descending = $false }
}

function Get-MarkdownFileCount {
    param([string]$Path, [switch]$Recurse)

    if (-not (Test-Path $Path)) {
        return 0
    }

    $parameters = @{
        Path = $Path
        File = $true
        Filter = '*.md'
        ErrorAction = 'SilentlyContinue'
    }

    if ($Recurse) {
        $parameters.Recurse = $true
    }

    return @((Get-ChildItem @parameters)).Count
}

function Get-ReadingQueueCount {
    param([string]$VaultPath)

    $queuePath = Join-Path $VaultPath 'Projects\Personal\Reading Queue.md'
    if (-not (Test-Path $queuePath)) {
        return 0
    }

    $text = Get-Content -Path $queuePath -Raw
    return @([regex]::Matches($text, '(?m)^\*\*\d+\.\*\*')).Count
}

function Get-NoteBreakdown {
    param([string]$VaultPath)

    $notesPath = Join-Path $VaultPath 'Notes'
    if (-not (Test-Path $notesPath)) {
        return @()
    }

    return @(Get-ChildItem -Path $notesPath -Directory | ForEach-Object {
        [PSCustomObject]@{
            Label = $_.Name
            Count = Get-MarkdownFileCount -Path $_.FullName -Recurse
        }
    } | Sort-Object @{ Expression = 'Count'; Descending = $true }, @{ Expression = 'Label'; Descending = $false })
}

$safeRoots = @(
    'Clippings',
    'Blog',
    'Notes\Concepts',
    'Notes\Patterns',
    'Notes\Frameworks'
)

$files = foreach ($root in $safeRoots) {
    $path = Join-Path $VaultPath $root
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -notmatch '\\(\.trash|Templates|Artifacts|copilot|\.agents)\\'
            }
    }
}

$notes = $files |
    Sort-Object LastWriteTime -Descending |
    ForEach-Object {
        $relative = Get-RelativePath $VaultPath $_.FullName
        $title = ConvertTo-PublicTitle $_
        if (-not (Test-IsPublicIndexNote -RelativePath $relative -Title $title)) {
            [PSCustomObject]@{
                Title = $title
                Kind = Get-NoteKind $relative
                RelativePath = $relative
                Updated = $_.LastWriteTime
            }
        }
    } |
    Select-Object -First $MaxRecent

$topicScores = @(Get-TopicScores $notes)
$activeTopics = @($topicScores | Where-Object { $_.Score -gt 0 } | Select-Object -First 4)
if ($activeTopics.Count -lt 4) {
    $activeTopics = @($topicScores | Select-Object -First 4)
}

$topicPositions = @('node-agentic', 'node-second-brain', 'node-adoption', 'node-governance')
$notePositions = @('node-capability', 'node-production', 'node-literacy', 'node-rag')

$nodes = @(
    [PSCustomObject]@{ Label = 'Current attention'; Type = 'core'; Class = 'constellation-node--core' }
)

for ($i = 0; $i -lt $activeTopics.Count; $i++) {
    $nodes += [PSCustomObject]@{
        Label = $activeTopics[$i].Label
        Type = 'topic'
        Class = $topicPositions[$i]
    }
}

$topicLabels = @($activeTopics | ForEach-Object { $_.Label })
$noteNodes = @(
    $notes |
        Where-Object { $_.Kind -eq 'Thinking' -and $topicLabels -notcontains $_.Title } |
        Sort-Object Title -Unique |
        Select-Object -First 4
)
for ($i = 0; $i -lt $noteNodes.Count; $i++) {
    $nodes += [PSCustomObject]@{
        Label = $noteNodes[$i].Title
        Type = 'note'
        Class = $notePositions[$i]
    }
}

$active = @($notes | Where-Object { $topicLabels -notcontains $_.Title } | Select-Object -First 4 | ForEach-Object {
    [PSCustomObject]@{
        Title = $_.Title
        Kind = $_.Kind
        Meta = switch ($_.Kind) {
            'Reading' { 'Recent clipping' }
            'Writing' { 'Writing signal' }
            default { 'Active note' }
        }
    }
})

$topTopic = $activeTopics | Select-Object -First 1
if (-not $topTopic) {
    $topTopic = [PSCustomObject]@{
        Label = 'Current attention'
        Summary = 'Recent vault activity, grouped into public-safe signals.'
        ClusterTitle = 'Recent ideas gathering momentum.'
    }
}

$bridges = @(
    [PSCustomObject]@{ From = 'AI adoption'; To = 'organisational capability' },
    [PSCustomObject]@{ From = 'Second brain'; To = 'personal tooling' },
    [PSCustomObject]@{ From = 'Governance'; To = 'responsible practice' }
)

$processedClippings = Get-MarkdownFileCount -Path (Join-Path $VaultPath 'Clippings\Processed')
$wikiNotes = Get-MarkdownFileCount -Path (Join-Path $VaultPath 'Notes') -Recurse
$blogFiles = Get-MarkdownFileCount -Path (Join-Path $VaultPath 'Blog')
$noteBreakdown = Get-NoteBreakdown -VaultPath $VaultPath

$payload = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    generatedLabel = (Get-Date).ToString('d MMMM yyyy')
    source = 'Public-safe vault summary'
    hero = [ordered]@{
        eyebrow = 'Thinking now'
        title = "A living map of what I'm thinking about."
        intro = 'Generated from a public-safe summary of my personal knowledge base: the things that have been recurring, connecting, or gathering momentum lately.'
    }
    stats = [ordered]@{
        notesSampled = @($notes).Count
        topics = @($activeTopics).Count
        readings = @($notes | Where-Object { $_.Kind -eq 'Reading' }).Count
        writing = @($notes | Where-Object { $_.Kind -eq 'Writing' }).Count
    }
    strongestCluster = [ordered]@{
        eyebrow = 'Strongest cluster'
        title = $topTopic.ClusterTitle
        summary = $topTopic.Summary
    }
    nodes = $nodes
    activeThreads = $active
    bridges = $bridges
    dashboard = [ordered]@{
        title = 'Vault dashboard'
        summary = 'A public-safe view of the durable knowledge base behind this page: processed sources, wiki notes, and public writing.'
        funnel = @(
            [ordered]@{ Label = 'Processed clippings'; Count = $processedClippings; Description = 'Sources triaged and connected' },
            [ordered]@{ Label = 'Wiki notes'; Count = $wikiNotes; Description = 'Synthesised concepts, frameworks, research, and patterns' },
            [ordered]@{ Label = 'Blog files'; Count = $blogFiles; Description = 'Public writing in the vault' }
        )
        breakdown = $noteBreakdown
    }
    updateNote = 'This page is periodically refreshed from a public-safe summary of my personal knowledge base.'
}

$outputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$json = $payload | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($OutputPath, $json, [System.Text.UTF8Encoding]::new($false))

Write-Host "Thinking data written to $OutputPath" -ForegroundColor Green
Write-Host "Sampled $(@($notes).Count) recent notes from $VaultPath" -ForegroundColor Gray
