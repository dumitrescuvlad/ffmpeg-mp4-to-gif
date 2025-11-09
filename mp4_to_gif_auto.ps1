
# mp4_to_gif_auto.ps1
# Batch convert all MP4 files in a folder to GIFs using FFmpeg.
# Processes up to 20 files in parallel, 33fps, 540px width, 5s max length.

param(
    [string]$InputFolder = ".",
    [string]$OutputFolder = ".\gifs",
    [int]$BatchSize = 20
)

# --- Checks ---
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "FFmpeg not found. Please install it and add it to PATH." -ForegroundColor Red
    exit 1
}

# Prepare output folder
if (-not (Test-Path -LiteralPath $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

# --- Settings ---
$fps = 33
$scale = 540
$duration = 5  # seconds limit

# Get all MP4 files (case-insensitive), files only
$files = Get-ChildItem -LiteralPath $InputFolder -Filter "*.mp4" -File
if ($files.Count -eq 0) {
    Write-Host "No MP4 files found in '$InputFolder'." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($files.Count) MP4 files. Processing in batches of $BatchSize..." -ForegroundColor Cyan

# --- Process in batches ---
for ($i = 0; $i -lt $files.Count; $i += $BatchSize) {
    $batch = $files[$i..([Math]::Min($i + $BatchSize - 1, $files.Count - 1))]
    $batchNum = [Math]::Floor($i / $BatchSize) + 1
    Write-Host "Starting batch $batchNum ($($batch.Count) files)..." -ForegroundColor Yellow

    $jobs = @()
    foreach ($file in $batch) {
        $input  = $file.FullName
        $name   = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $output = Join-Path $OutputFolder "$name.gif"

        $jobs += Start-Job -ScriptBlock {
            param($input, $output, $fps, $scale, $duration)

            $ErrorActionPreference = 'Stop'
            $palette = Join-Path $env:TEMP ("palette_{0}.png" -f [guid]::NewGuid().ToString())
            try {
                # Palette generation
                ffmpeg -y -t $duration -i "$input" -vf "fps=${fps},scale=${scale}:-1:flags=lanczos,palettegen" "$palette" 2>&1 | Out-Null
                # GIF encode using palette
                ffmpeg -y -t $duration -i "$input" -i "$palette" -filter_complex "fps=${fps},scale=${scale}:-1:flags=lanczos[x];[x][1:v]paletteuse" "$output" 2>&1 | Out-Null
                Write-Output ("OK  : {0}" -f $output)
            }
            catch {
                Write-Output ("FAIL: {0}`n{1}" -f $input, $_ | Out-String)
            }
            finally {
                if (Test-Path -LiteralPath $palette) { Remove-Item -LiteralPath $palette -ErrorAction SilentlyContinue }
            }
        } -ArgumentList $input, $output, $fps, $scale, $duration
    }

    # Wait and collect results
    $jobs | Wait-Job | Out-Null
    $results = $jobs | Receive-Job
    $jobs | Remove-Job | Out-Null

    # Show per-file results for this batch
    $results | ForEach-Object { Write-Host $_ }

    Write-Host "Batch $batchNum completed." -ForegroundColor Green
}

Write-Host "All conversions completed. GIFs saved in: $OutputFolder" -ForegroundColor Cyan
