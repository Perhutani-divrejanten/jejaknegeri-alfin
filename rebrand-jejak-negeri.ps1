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
    $Content = $Content -replace '&nbsp;|&#160;', ' '

    return $Content
}

function Update-BrandContent {
    param(
        [string]$Content,
        [bool]$IsHtml = $false
    )

    if ($null -eq $Content) { return $Content }

    $Content = Normalize-Content $Content

    $pairs = @(
        @{ Old = 'Pusat Informasi'; New = 'Jejak Negeri' },
        @{ Old = 'PusatInformasi'; New = 'JejakNegeri' },
        @{ Old = 'pusatinformasi'; New = 'jejakknegeri' },
        @{ Old = 'JejakNegeri@gmail.com'; New = 'jejakknegeri@gmail.com' },
        @{ Old = 'Jejak Negeri@gmail.com'; New = 'jejakknegeri@gmail.com' },
        @{ Old = 'Warta Janten'; New = 'Jejak Negeri' },
        @{ Old = 'WartaJanten'; New = 'JejakNegeri' },
        @{ Old = 'wartajanten'; New = 'jejakknegeri' },
        @{ Old = 'Indonesia Daily'; New = 'Jejak Negeri' },
        @{ Old = 'IndonesiaDaily'; New = 'JejakNegeri' },
        @{ Old = 'indonesiadaily'; New = 'jejakknegeri' },
        @{ Old = 'PUSAT<span style="color: #5F1F7F; font-weight: 400; font-size: 15px; margin-left: 4px;">INFORMASI'; New = 'JEJAK<span style="color: #3F5F1F; font-weight: 400; font-size: 15px; margin-left: 4px;">NEGERI' },
        @{ Old = 'PUSAT<span style="color: #5F1F7F; font-weight: normal; font-size: 18px; margin-left: 2px;">INFORMASI'; New = 'JEJAK<span style="color: #3F5F1F; font-weight: 400; font-size: 15px; margin-left: 4px;">NEGERI' },
        @{ Old = 'WARTA<span style="color: #1E3A5F; font-weight: normal; font-size: 18px; margin-left: 2px;">JANTEN'; New = 'JEJAK<span style="color: #3F5F1F; font-weight: 400; font-size: 15px; margin-left: 4px;">NEGERI' },
        @{ Old = '#F59E0B'; New = '#991B1B' },
        @{ Old = '#5F1F7F'; New = '#3F5F1F' },
        @{ Old = '#78350F'; New = '#450A0A' },
        @{ Old = '#FFCC00'; New = '#991B1B' },
        @{ Old = '#ffcc00'; New = '#991B1B' },
        @{ Old = '#fc0'; New = '#991B1B' },
        @{ Old = '#1E2024'; New = '#450A0A' },
        @{ Old = '#1e2024'; New = '#450A0A' },
        @{ Old = '#31404B'; New = '#3F5F1F' },
        @{ Old = '#31404b'; New = '#3F5F1F' },
        @{ Old = '#065F46'; New = '#991B1B' },
        @{ Old = '#1E3A5F'; New = '#3F5F1F' },
        @{ Old = '#022C22'; New = '#450A0A' },
        @{ Old = '#b38f00'; New = '#450A0A' },
        @{ Old = 'rgb(245, 158, 11)'; New = 'rgb(153, 27, 27)' },
        @{ Old = 'rgb(95, 31, 127)'; New = 'rgb(63, 95, 31)' },
        @{ Old = 'rgb(120, 53, 15)'; New = 'rgb(69, 10, 10)' },
        @{ Old = 'rgba(255,204,0,0.25)'; New = 'rgba(153,27,27,0.25)' },
        @{ Old = 'rgba(255,204,0,0.5)'; New = 'rgba(153,27,27,0.5)' },
        @{ Old = 'rgba(222,179,6,0.5)'; New = 'rgba(153,27,27,0.5)' }
    )

    foreach ($pair in $pairs) {
        $Content = $Content -replace [regex]::Escape($pair.Old), $pair.New
    }

    $Content = $Content -replace '(?i)\b(?:pusatinformasi|wartajanten|indonesiadaily)(?:33)?@gmail\.com\b', 'jejakknegeri@gmail.com'
    $Content = $Content -replace 'https://twitter\.com(?:/[A-Za-z0-9_\.@-]+)?', 'https://twitter.com/jejakknegeri'
    $Content = $Content -replace 'https://facebook\.com(?:/[A-Za-z0-9_\.@-]+)?', 'https://facebook.com/jejakknegeri'
    $Content = $Content -replace 'https://instagram\.com(?:/[A-Za-z0-9_\.@-]+)?', 'https://instagram.com/jejakknegeri'
    $Content = $Content -replace 'https://youtube\.com(?:/@[A-Za-z0-9_\.-]+|/[A-Za-z0-9_\.@-]+)?', 'https://youtube.com/@jejakknegeri'
    $Content = $Content -replace 'https://linkedin\.com/company(?:/[A-Za-z0-9_\.-]+)?', 'https://linkedin.com/company/jejakknegeri'
    $Content = $Content -replace 'mail/\?view=cm&fs=1&to=[^"''\s<]+', 'mail/?view=cm&fs=1&to=jejakknegeri@gmail.com'

    if ($IsHtml) {
        $brandText = '<span style="font-weight: 700; color: #991B1B; font-size: 24px; letter-spacing: -0.5px;">JEJAK<span style="color: #3F5F1F; font-weight: 400; font-size: 15px; margin-left: 4px;">NEGERI</span></span>'

        $Content = [regex]::Replace(
            $Content,
            '(<a[^>]*class="navbar-brand[^\"]*"[^>]*>)(.*?)(</a>)',
            '$1' + "`r`n            " + $brandText + "`r`n        " + '$3',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        $Content = [regex]::Replace(
            $Content,
            '<img[^>]*src="[^\"]*(?:brand|logo)[^\"]*\.png"[^>]*>',
            $brandText,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        $Content = $Content -replace '(<title>\s*)(?:Jejak Negeri|Pusat Informasi|Warta Janten|Indonesia Daily)\s*-\s*([^<]+?)\s*(</title>)', '$1$2 - Jejak Negeri$3'
        $Content = $Content -replace '(<title>[^<]*?)\b(?:jejakknegeri|pusatinformasi|wartajanten|indonesiadaily)\b([^<]*</title>)', '$1Jejak Negeri$2'

        if ($Content -notmatch '(?is)<title>[^<]*Jejak Negeri[^<]*</title>') {
            $Content = [regex]::Replace(
                $Content,
                '<title>\s*([^<]+?)\s*</title>',
                '<title>$1 - Jejak Negeri</title>',
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
        }

        $Content = $Content -replace '\s*-\s*Jejak Negeri\s*-\s*Jejak Negeri', ' - Jejak Negeri'
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
Get-ChildItem -Recurse -Include *.html | ForEach-Object {
    if ($_.PSIsContainer) { return }
    if ($_.FullName -like '*\.bak*' -or $_.FullName -like '*\node_modules\*') { return }

    $category = $null
    if ($_.FullName -like "*\article\*") {
        $category = 'article_pages'
    }
    elseif ($_.DirectoryName -eq $WorkspaceRoot) {
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
Get-ChildItem -Path $WorkspaceRoot -Recurse -Include *.md,*.txt,*.toml -File |
    Where-Object { $_.FullName -notlike '*\.bak*' -and $_.FullName -notlike '*\node_modules\*' } |
    ForEach-Object {
        [void](Process-File -FilePath $_.FullName -Category 'docs')
    }

# Ensure package names are exact
$rootPackage = Join-Path $WorkspaceRoot 'package.json'
if (Test-Path -LiteralPath $rootPackage) {
    $pkg = Get-Content -LiteralPath $rootPackage -Raw -Encoding UTF8
    $pkg = $pkg -replace '"name"\s*:\s*"[^"]+"', '"name": "jejakknegeri"'
    Set-Content -LiteralPath $rootPackage -Value $pkg -Encoding UTF8
    Add-ChangedFile -Category 'package' -FilePath $rootPackage
}

$rootPackageLock = Join-Path $WorkspaceRoot 'package-lock.json'
if (Test-Path -LiteralPath $rootPackageLock) {
    $pkg = Get-Content -LiteralPath $rootPackageLock -Raw -Encoding UTF8
    $pkg = $pkg -replace '"name"\s*:\s*"[^"]+"', '"name": "jejakknegeri"'
    Set-Content -LiteralPath $rootPackageLock -Value $pkg -Encoding UTF8
    Add-ChangedFile -Category 'package' -FilePath $rootPackageLock
}

$toolsPackage = Join-Path $WorkspaceRoot 'tools\package.json'
if (Test-Path -LiteralPath $toolsPackage) {
    $pkg = Get-Content -LiteralPath $toolsPackage -Raw -Encoding UTF8
    $pkg = $pkg -replace '"name"\s*:\s*"[^"]+"', '"name": "jejakknegeri-article-generator"'
    Set-Content -LiteralPath $toolsPackage -Value $pkg -Encoding UTF8
    Add-ChangedFile -Category 'package' -FilePath $toolsPackage
}

$toolsPackageLock = Join-Path $WorkspaceRoot 'tools\package-lock.json'
if (Test-Path -LiteralPath $toolsPackageLock) {
    $pkg = Get-Content -LiteralPath $toolsPackageLock -Raw -Encoding UTF8
    $pkg = $pkg -replace '"name"\s*:\s*"[^"]+"', '"name": "jejakknegeri-article-generator"'
    Set-Content -LiteralPath $toolsPackageLock -Value $pkg -Encoding UTF8
    Add-ChangedFile -Category 'package' -FilePath $toolsPackageLock
}

Write-Host ''
Write-Host 'main pages   : ' $changed.main_pages.Count
Write-Host 'article pages: ' $changed.article_pages.Count
Write-Host 'css          : ' $changed.css.Count
Write-Host 'package      : ' $changed.package.Count
Write-Host 'docs         : ' $changed.docs.Count
Write-Host 'Rebrand Jejak Negeri selesai ✅' -ForegroundColor Green

