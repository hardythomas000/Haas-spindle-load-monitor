# convert_dprnt_to_csv.ps1
# Converts Haas DPRNT output from O9010 spindle load logger to CSV
# Usage: powershell -ExecutionPolicy Bypass -File convert_dprnt_to_csv.ps1 -InputPath "DPRNT.OUT"
#
# O9010 outputs comma-separated lines:
#   SAMPLE,TIME_S,LOAD_PCT,RPM,POWER_KW,CUM_ENERGY_KJ
#   0001, 01.00, 42.30, 08100., 04.74, 04.74
#   ...
#   LOG_COMPLETE

param(
    [string]$InputPath  = "DPRNT.OUT",
    [string]$OutputPath = "spindle_load_log.csv"
)

if (-not (Test-Path -LiteralPath $InputPath)) {
    throw "Input file not found: $InputPath"
}

$lines = Get-Content -LiteralPath $InputPath
$csv = @()
$dataRows = 0

foreach ($line in $lines) {
    $trimmed = $line.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
    if ($trimmed -eq "LOG_COMPLETE") { continue }

    if ($trimmed -match '^SAMPLE') {
        # Header line — pass through
        $csv += $trimmed
    }
    elseif ($trimmed -match '^\d') {
        # Data line — clean up DPRNT spacing
        $fields = $trimmed -split ',' | ForEach-Object { $_.Trim() }
        $csv += $fields -join ','
        $dataRows++
    }
}

if ($dataRows -eq 0) {
    throw "No data rows parsed from $InputPath"
}

$csv | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Wrote $dataRows samples to $OutputPath"
