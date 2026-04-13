$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$WorkspaceRoot = $PSScriptRoot
Set-Location $WorkspaceRoot

$changed = @{
    main_pages = New-Object 'System.Collections.Generic.HashSet[string]'
    article_pages = New-Object 'System.Collections.Generic.HashSet[string]'
    css = New-Object 'System.Collections.Generic.HashSet[string]'
    package = New-Object 'System.Collections.Generic.HashSet[string]'
    docs = New-Object 'System.Collections.Generic.HashSet[string]'
}

function Add-ChangedFile {
    param(
        [string]$Category,
        [string]$FilePath
    )

    if (-not $changed.ContainsKey($Category)) { return }
    $resolved = Resolve-Path -LiteralPath $FilePath -ErrorAction SilentlyContinue
    if ($resolved) {
        [void]$changed[$Category].Add($resolved.Path)
    }
}

function Normalize-Content {
    param([string]$Content)

    if ($null -eq $Content) { return $Content }

    $Content = $Content -replace '[\u201C\u201D]', '"'
    $Content = $Content -replace '[\u2018\u2019]', "'"
    $Content = $Content -replace '[\u2013\u2014]', '-'
    $Content = $Content -replace '[\uFFFD\u00A0]', ' '
    $Content = $Content -replace '&nbsp;', ' '

    return $Content
}

function Update-BrandContent {
    param(
        [string]$Content,
        [bool]$IsHtml = $false
    )

    $Content = Normalize-Content $Content

    $pairs = @(
        @{ Old = 'PUSAT<span style="color: #5F1F7F; font-weight: normal; font-size: 18px; margin-left: 2px;">JANTEN'; New = 'PUSAT<span style="color: #5F1F7F; font-weight: 400; font-size: 15px; margin-left: 4px;">INFORMASI' },
        @{ Old = 'WARTA<span style="color: #1E3A5F; font-weight: normal; font-size: 18px; margin-left: 2px;">JANTEN'; New = 'PUSAT<span style="color: #5F1F7F; font-weight: 400; font-size: 15px; margin-left: 4px;">INFORMASI' },
        @{ Old = ('Warta' + ' Janten'); New = 'Pusat Informasi' },
        @{ Old = ('Warta' + 'Janten'); New = 'pusatinformasi' },
        @{ Old = ('warta' + 'anten'); New = 'pusatinformasi' },
        @{ Old = ('warta' + 'janten33@gmail.com'); New = 'pusatinformasi@gmail.com' },
        @{ Old = ('warta' + 'janten@gmail.com'); New = 'pusatinformasi@gmail.com' },
        @{ Old = ('Jejak' + ' Negeri'); New = 'Pusat Informasi' },
        @{ Old = ('Jejak' + 'Negeri'); New = 'pusatinformasi' },
        @{ Old = ('jejak' + 'knegeri33@gmail.com'); New = 'pusatinformasi@gmail.com' },
        @{ Old = ('jejak' + 'knegeri@gmail.com'); New = 'pusatinformasi@gmail.com' },
        @{ Old = ('warta' + 'janten'); New = 'pusatinformasi' },
        @{ Old = ('jejak' + 'knegeri'); New = 'pusatinformasi' },
        @{ Old = 'PusatInformasi33@gmail.com'; New = 'pusatinformasi@gmail.com' },
        @{ Old = 'PusatInformasi@gmail.com'; New = 'pusatinformasi@gmail.com' },
        @{ Old = 'PusatInformasi'; New = 'pusatinformasi' },
        @{ Old = 'WARTA'; New = 'PUSAT' },
        @{ Old = 'JANTEN'; New = 'INFORMASI' },
        @{ Old = '#065F46'; New = '#F59E0B' },
        @{ Old = '#1E3A5F'; New = '#5F1F7F' },
        @{ Old = '#022C22'; New = '#78350F' },
        @{ Old = '#FFCC00'; New = '#F59E0B' },
        @{ Old = '#ffcc00'; New = '#F59E0B' },
        @{ Old = '#fc0'; New = '#F59E0B' },
        @{ Old = '#1E2024'; New = '#78350F' },
        @{ Old = '#1e2024'; New = '#78350F' },
        @{ Old = '#b38f00'; New = '#78350F' },
        @{ Old = 'rgb(6, 95, 70)'; New = 'rgb(245, 158, 11)' },
        @{ Old = 'rgb(2, 44, 34)'; New = 'rgb(120, 53, 15)' },
        @{ Old = 'rgb(30, 58, 95)'; New = 'rgb(95, 31, 127)' }
    )

    foreach ($pair in $pairs) {
        $Content = $Content -replace [regex]::Escape($pair.Old), $pair.New
    }

    if ($IsHtml) {
        $brandText = '<span style="font-weight: 700; color: #F59E0B; font-size: 24px; letter-spacing: -0.5px;">PUSAT<span style="color: #5F1F7F; font-weight: 400; font-size: 15px; margin-left: 4px;">INFORMASI</span></span>'
        $Content = [regex]::Replace(
            $Content,
            '(<a[^>]*class="navbar-brand[^\"]*"[^>]*>)(.*?)(</a>)',
            '$1' + "`r`n            " + $brandText + "`r`n        " + '$3',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        $Content = [regex]::Replace($Content, '<img[^>]*src="[^\"]*(?:brand|logo)[^\"]*\.png"[^>]*>', $brandText, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $Content = $Content -replace '<title>\s*Pusat Informasi\s*-\s*Berita Terkini Indonesia\s*</title>', '<title>Berita Terkini Indonesia - Pusat Informasi</title>'
        if ($Content -notmatch '(?is)<title>[^<]*Pusat Informasi[^<]*</title>') {
            $Content = [regex]::Replace($Content, '<title>\s*([^<]+?)\s*</title>', '<title>$1 - Pusat Informasi</title>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
        $Content = $Content -replace '(<title>[^<]*?)\bpusatinformasi\b([^<]*</title>)', '$1Pusat Informasi$2'
        $Content = $Content -replace '(<meta[^>]+content=")([^\"]*?)\bpusatinformasi\b([^\"]*")', '$1$2Pusat Informasi$3'
    }

    return $Content
}

function Process-File {
    param(
        [string]$FilePath,
        [string]$Category,
        [bool]$IsHtml = $false
    )

    $original = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
    $updated = Update-BrandContent -Content $original -IsHtml:$IsHtml

    if ($updated -ne $original) {
        Set-Content -LiteralPath $FilePath -Value $updated -Encoding UTF8
        if ($Category) {
            Add-ChangedFile -Category $Category -FilePath $FilePath
        }
        return $true
    }

    return $false
}

if (Test-Path -LiteralPath 'articles.json') {
    Copy-Item -LiteralPath 'articles.json' -Destination 'articles.json.bak' -Force
    Write-Host 'Backup created: articles.json.bak' -ForegroundColor Green
}

# HTML rebrand and encoding normalization
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include *.html -File |
    Where-Object { $_.FullName -notlike '*\.bak*' -and $_.FullName -notlike '*\node_modules\*' } |
    ForEach-Object {
        $category = $null
        if ($_.FullName -like "*\article\*") {
            $category = 'article_pages'
        } elseif ($_.DirectoryName -eq $WorkspaceRoot) {
            $category = 'main_pages'
        }

        [void](Process-File -FilePath $_.FullName -Category $category -IsHtml:$true)
    }

# CSS theme updates
Get-ChildItem -Path (Join-Path $WorkspaceRoot 'css') -Recurse -Include *.css -File -ErrorAction SilentlyContinue |
    ForEach-Object {
        [void](Process-File -FilePath $_.FullName -Category 'css')
    }

# Package metadata and JSON/config updates
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include package.json,package-lock.json,*.json -File |
    Where-Object { $_.FullName -notlike '*\.bak*' -and $_.FullName -notlike '*\node_modules\*' } |
    ForEach-Object {
        $category = $null
        if ($_.Name -like 'package*.json') {
            $category = 'package'
        }
        [void](Process-File -FilePath $_.FullName -Category $category)
    }

# Docs/config text updates
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include *.md,*.txt,*.toml,*.ps1 -File |
    Where-Object {
        $_.FullName -notlike '*\.bak*' -and
        $_.FullName -notlike '*\node_modules\*' -and
        $_.Name -notin @('rebrand-pusat-informasi.ps1', 'final-verification.ps1', 'replace-logo.ps1')
    } |
    ForEach-Object {
        $category = $null
        if ($_.Extension -in @('.md', '.txt', '.toml')) {
            $category = 'docs'
        }
        [void](Process-File -FilePath $_.FullName -Category $category)
    }

# Remove remaining legacy brand-image references in generator
$generatorPath = Join-Path $WorkspaceRoot 'tools\generate.js'
if (Test-Path -LiteralPath $generatorPath) {
    $generator = Get-Content -LiteralPath $generatorPath -Raw -Encoding UTF8
    $originalGenerator = $generator
    $generator = $generator -replace "!\s*src\.includes\('(?:brand|logo)[^']*\.png'\)\s*&&\s*", "!src.includes('favicon.ico') && "
    $generator = $generator -replace "return\s+'img\/(?:brand|logo)[^']*\.png';", "return 'img/news-800x500-1.jpg';"
    $generator = Update-BrandContent -Content $generator

    if ($generator -ne $originalGenerator) {
        Set-Content -LiteralPath $generatorPath -Value $generator -Encoding UTF8
        Add-ChangedFile -Category 'docs' -FilePath $generatorPath
    }
}

# Ensure package names are exact
$rootPackage = Join-Path $WorkspaceRoot 'package.json'
if (Test-Path -LiteralPath $rootPackage) {
    $pkg = Get-Content -LiteralPath $rootPackage -Raw -Encoding UTF8
    $pkg = $pkg -replace '"name"\s*:\s*"[^"]+"', '"name": "pusatinformasi"'
    Set-Content -LiteralPath $rootPackage -Value $pkg -Encoding UTF8
    Add-ChangedFile -Category 'package' -FilePath $rootPackage
}

$toolsPackage = Join-Path $WorkspaceRoot 'tools\package.json'
if (Test-Path -LiteralPath $toolsPackage) {
    $pkg = Get-Content -LiteralPath $toolsPackage -Raw -Encoding UTF8
    $pkg = $pkg -replace '"name"\s*:\s*"[^"]+"', '"name": "pusatinformasi-article-generator"'
    Set-Content -LiteralPath $toolsPackage -Value $pkg -Encoding UTF8
    Add-ChangedFile -Category 'package' -FilePath $toolsPackage
}

Write-Host ''
Write-Host 'Rebrand Pusat Informasi selesai ✅' -ForegroundColor Green
Write-Host ('main pages   : ' + $changed.main_pages.Count)
Write-Host ('article pages: ' + $changed.article_pages.Count)
Write-Host ('css          : ' + $changed.css.Count)
Write-Host ('package      : ' + $changed.package.Count)
Write-Host ('docs         : ' + $changed.docs.Count)
