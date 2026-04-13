$ErrorActionPreference = 'Stop'
$WorkspaceRoot = $PSScriptRoot

Write-Host '========== FINAL VERIFICATION - JEJAK NEGERI ==========' -ForegroundColor Cyan
Write-Host ''

$issues = @()
$scannableFiles = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include '*.html', '*.css', '*.json', '*.md', '*.toml' -File |
    Where-Object {
        $_.FullName -notlike '*\node_modules\*' -and
        $_.FullName -notlike '*\.bak*'
    }

Write-Host '1. Checking for legacy branding...' -ForegroundColor Yellow
$legacyBrandMatches = $scannableFiles |
    Select-String -Pattern 'Warta\s*Janten|WartaJanten|wartajanten|Pusat\s+Informasi|PusatInformasi|pusatinformasi|Indonesia\s*Daily|IndonesiaDaily|indonesiadaily' -ErrorAction SilentlyContinue

if ($legacyBrandMatches) {
    $issues += $legacyBrandMatches
    Write-Host "   ⚠️  Legacy branding still appears in $($legacyBrandMatches.Count) place(s)" -ForegroundColor Yellow
} else {
    Write-Host '   ✅ No legacy branding references found' -ForegroundColor Green
}

Write-Host '2. Checking for logo.png references...' -ForegroundColor Yellow
$logoMatches = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include '*.html', '*.js', '*.md', '*.json' -File |
    Where-Object { $_.FullName -notlike '*\node_modules\*' -and $_.FullName -notlike '*\.bak*' } |
    Select-String -Pattern 'logo\.png' -ErrorAction SilentlyContinue

if ($logoMatches) {
    $issues += $logoMatches
    Write-Host "   ⚠️  logo.png references found: $($logoMatches.Count)" -ForegroundColor Yellow
} else {
    Write-Host '   ✅ No logo.png references found' -ForegroundColor Green
}

Write-Host '3. Checking required theme colors...' -ForegroundColor Yellow
$cssFiles = Get-ChildItem -Path (Join-Path $WorkspaceRoot 'css') -Recurse -Include '*.css' -File -ErrorAction SilentlyContinue
$requiredColors = @('#991B1B', '#450A0A', '#3F5F1F')
$colorsFound = 0
foreach ($color in $requiredColors) {
    if ($cssFiles | Select-String -Pattern ([regex]::Escape($color)) -Quiet) {
        $colorsFound++
        Write-Host "   ✅ Found $color" -ForegroundColor Green
    }
    else {
        $issues += "Missing color: $color"
        Write-Host "   ⚠️  Missing $color" -ForegroundColor Yellow
    }
}

Write-Host '4. Checking new branding presence...' -ForegroundColor Yellow
$newBrandingFound = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include '*.html', '*.md', '*.json', '*.toml' -File |
    Where-Object { $_.FullName -notlike '*\node_modules\*' -and $_.FullName -notlike '*\.bak*' } |
    Select-String -Pattern 'Jejak Negeri|jejakknegeri@gmail\.com|jejakknegeri' -ErrorAction SilentlyContinue |
    Measure-Object
Write-Host "   ✅ Found Jejak Negeri branding in $($newBrandingFound.Count) place(s)" -ForegroundColor Green

Write-Host '5. Checking package metadata...' -ForegroundColor Yellow
$pkgFiles = @(
    (Join-Path $WorkspaceRoot 'package.json'),
    (Join-Path $WorkspaceRoot 'tools\package.json')
) | Where-Object { Test-Path -LiteralPath $_ }

$pkgOk = 0
foreach ($pkg in $pkgFiles) {
    $content = Get-Content -LiteralPath $pkg -Raw -Encoding UTF8
    if ($content -match '"name"\s*:\s*"(jejakknegeri|jejakknegeri-article-generator)"') {
        $pkgOk++
        Write-Host "   ✅ $(Split-Path $pkg -Leaf) metadata is correct" -ForegroundColor Green
    }
    else {
        $issues += "Package metadata mismatch: $pkg"
        Write-Host "   ⚠️  $(Split-Path $pkg -Leaf) metadata is not updated" -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host '========== SUMMARY ==========' -ForegroundColor Cyan
Write-Host "Files checked          : $($scannableFiles.Count)" -ForegroundColor White
Write-Host "Legacy branding hits   : $(if ($legacyBrandMatches) { $legacyBrandMatches.Count } else { 0 })" -ForegroundColor White
Write-Host "logo.png hits          : $(if ($logoMatches) { $logoMatches.Count } else { 0 })" -ForegroundColor White
Write-Host "Required colors found  : $colorsFound/3" -ForegroundColor White
Write-Host "Package files verified : $pkgOk/$($pkgFiles.Count)" -ForegroundColor White
Write-Host ''

if (-not $legacyBrandMatches -and -not $logoMatches -and $colorsFound -eq 3 -and $pkgOk -eq $pkgFiles.Count) {
    Write-Host 'Rebrand Jejak Negeri selesai ✅' -ForegroundColor Green
}
else {
    Write-Host 'Verification completed with follow-up items.' -ForegroundColor Yellow
}


