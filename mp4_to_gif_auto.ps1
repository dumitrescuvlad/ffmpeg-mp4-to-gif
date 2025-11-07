# mp4_to_gif_auto.ps1
# Batch convert all MP4 files in a folder to GIFs using FFmpeg.
# Processes 20 files in parallel, 33fps, 540px width, 5s max length.

param(
    [string]$InputFolder = ".",
    [string]$OutputFolder = ".\gifs",
    [int]$BatchSize = 20
)

# Check for FFmpeg
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "FFmpeg not found. Please install it and add it to PATH." -ForegroundColor Red
    exit 1
}

# Prepare output folder
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$fps = 33
$scale = 540
$duration = 5  # seconds limit

# Get all MP4 files
$files = Get-ChildItem -Path $InputFolder -Filter "*.mp4"

if ($files.Count -eq 0) {
    Write-Host "No MP4 files found in '$InputFolder'." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($files.Count) MP4 files. Processing in batches of $BatchSize..." -ForegroundColor Cyan

# Process in batches of 20
for ($i = 0; $i -lt $files.Count; $i += $BatchSize) {
    $batch = $files[$i..([Math]::Min($i + $BatchSize - 1, $files.Count - 1))]
    Write-Host "Starting batch $([Math]::Floor($i / $BatchSize) + 1) ($($batch.Count) files)..." -ForegroundColor Yellow

    $jobs = @()
    foreach ($file in $batch) {
        $input = $file.FullName
        $name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $output = Join-Path $OutputFolder "$name.gif"

        $jobs += Start-Job -ScriptBlock {
            param($input, $output, $fps, $scale, $duration)
            $palette = "$env:TEMP\palette_$([guid]::NewGuid().ToString()).png"
            ffmpeg -y -t $duration -i "$input" -vf "fps=$fps,scale=$scale:-1:flags=lanczos,palettegen" "$palette" | Out-Null
            ffmpeg -y -t $duration -i "$input" -i "$palette" -filter_complex "fps=$fps,scale=$scale:-1:flags=lanczos[x];[x][1:v]paletteuse" "$output" | Out-Null
            Remove-Item "$palette" -ErrorAction SilentlyContinue
        } -ArgumentList $input, $output, $fps, $scale, $duration
    }

    # Wait for current batch to finish
    $jobs | Wait-Job | Out-Null
    $jobs | Receive-Job | Out-Null
    $jobs | Remove-Job | Out-Null

    Write-Host "Batch completed." -ForegroundColor Green
}

Write-Host "All conversions completed. GIFs saved in: $OutputFolder" -ForegroundColor Cyan
