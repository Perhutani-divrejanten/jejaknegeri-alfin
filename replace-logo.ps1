# Script untuk menyegarkan logo teks brand di semua file HTML

$ErrorActionPreference = 'Stop'
$WorkspaceRoot = $PSScriptRoot
$htmlFiles = Get-ChildItem -Path $WorkspaceRoot -Recurse -Include "*.html" -File

$textBasedLogo = @"
<span style="font-weight: 700; color: #F59E0B; font-size: 24px; letter-spacing: -0.5px;">PUSAT<span style="color: #5F1F7F; font-weight: 400; font-size: 15px; margin-left: 4px;">INFORMASI</span></span>
"@

$replaceCount = 0

foreach ($file in $htmlFiles) {
    try {
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        $newContent = [regex]::Replace(
            $content,
            '(<a[^>]*class="navbar-brand[^"]*"[^>]*>)(.*?)(</a>)',
            '$1' + "`r`n            " + $textBasedLogo + "`r`n        " + '$3',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        $newContent = [regex]::Replace($newContent, '<img[^>]*src="(?:\.\./)?img/[^\"]*(?:brand|logo)[^\"]*\.png"[^>]*>', $textBasedLogo, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

        if ($newContent -ne $content) {
            Set-Content -LiteralPath $file.FullName -Value $newContent -Encoding UTF8
            $replaceCount++
            Write-Host "Updated brand block in: $($file.Name)"
        }
    } catch {
        Write-Host "Error processing $($file.FullName): $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Brand block refresh complete!"
Write-Host "Total files updated: $replaceCount"

