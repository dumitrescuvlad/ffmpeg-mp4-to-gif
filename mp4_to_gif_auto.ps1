<#  
    mp4_to_gif_auto.ps1
    -------------------------------------------
    Converts all videos in the current folder into GIFs.
    • FPS: 33
    • Size: 540xAuto (keeps aspect ratio)
    • Duration: first 5 seconds
    • Batch size: 20 (runs 20 conversions in parallel)
    • Output folder: ./gifs (auto-created)
#>

param(
    [int]$BatchSize   = 20,
    [int]$Fps         = 33,
    [int]$Width       = 540,
    [int]$MaxSeconds  = 5,
    [switch]$SkipIfExists
)

# --- Check ffmpeg ---
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    Write-Error "ffmpeg not found in PATH. Install ffmpeg and ensure it's accessible from PowerShell."
    exit 1
}
$ffmpegPath = $ffmpeg.Source

# --- Gather video files in current folder ---
$extensions = @('.mp4','.mov','.mkv','.avi','.m4v','.wmv','.webm','.mts','.m2ts','.3gp')
$files = Get-ChildItem -File | Where-Object { $extensions -contains $_.Extension.ToLower() }

if (-not $files -or $files.Count -eq 0) {
    Write-Host "No video files found in: $PWD"
    exit 0
}

# --- Prepare output directory ---
$outDir = Join-Path $PWD 'gifs'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# --- FFmpeg filter for smooth high-quality GIFs ---
$filter = "[0:v]fps=$Fps,scale=${Width}:-2:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=full[pal];[s1][pal]paletteuse=dither=sierra2_4a"

# --- Process in batches ---
$total = $files.Count
$index = 0
while ($index -lt $total) {
    $batch = $files[$index..([math]::Min($index + $BatchSize - 1, $total - 1))]
    Write-Host "`nProcessing batch $([int]($index / $BatchSize) + 1) of $([math]::Ceiling($total / $BatchSize)) - $($batch.Count) file(s)..."

    $jobs = @()
    foreach ($f in $batch) {
        $outPath = Join-Path $outDir ("{0}.gif" -f [System.IO.Path]::GetFileNameWithoutExtension($f.Name))
        if ($SkipIfExists -and (Test-Path $outPath)) {
            Write-Host "Skipping existing: $($f.Name)"
            continue
        }

        $jobs += Start-Job -Name $f.Name -ScriptBlock {
            param($ffmpegPath, $inFile, $outFile, $filterGraph, $maxSec)
            & $ffmpegPath -y -i $inFile -t $maxSec -filter_complex $filterGraph -an $outFile 2>&1 | Out-Null
            return $LASTEXITCODE
        } -ArgumentList $ffmpegPath, $f.FullName, $outPath, $filter, $MaxSeconds
    }

    if ($jobs.Count -gt 0) {
        Wait-Job -Job $jobs | Out-Null
        foreach ($j in $jobs) {
            if ($j.State -eq 'Completed') {
                Write-Host "[OK] $($j.Name)"
            } else {
                Write-Warning "[FAIL] $($j.Name) -> $($j.State)"
            }
            Remove-Job $j
        }
    }

    $index += $BatchSize
}

Write-Host "`n Conversion completed! GIFs saved in: $outDir"
