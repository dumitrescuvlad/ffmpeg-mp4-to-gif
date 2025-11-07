## mp4_to_gif_auto.ps1

### Description

`mp4_to_gif_auto.ps1` is a PowerShell script that batch converts `.mp4` videos into high-quality animated GIFs using **FFmpeg**.  
It automates the conversion process by scanning a folder for video files, processing them in parallel for speed, and saving the resulting GIFs into a dedicated output folder.

The default configuration converts videos to 5-second GIFs at **33 FPS** and **540 px** width (height automatically adjusted), but all settings such as duration, frame rate, resolution, and batch size can be easily customized in the script or passed as arguments.  
You can adapt it for short clips, previews, or lightweight GIF exports according to your preferences.

---

### Features

- Converts all `.mp4` files in a folder automatically
- Processes **20 files in parallel** for faster performance
- Uses an optimized FFmpeg color palette for high-quality results
- Limits GIF duration to **5 seconds** by default (configurable)
- Saves outputs in a dedicated `gifs/` subfolder
- Fully customizable settings (FPS, scale, duration, batch size)

---

### Requirements

- **Windows PowerShell** (version 5 or higher < preferable >)
- **FFmpeg** installed and added to your system PATH
  - Download: [https://ffmpeg.org/download.html](https://ffmpeg.org/download.html)

---

### How to Use

#### 1. Setup

1. Place the script `mp4_to_gif_auto.ps1` in the same folder as your `.mp4` videos.
2. Open **PowerShell** in that folder.

#### 2. Run the script

```powershell
./mp4_to_gif_auto.ps1
```

The script will:

- Detect all `.mp4` files in the current folder
- Convert each to a 5-second, 33 FPS GIF (540 px width)
- Save them into a subfolder named `gifs/`

#### 3. Optional arguments

You can specify a custom input folder, output folder, and batch size:

```powershell
./mp4_to_gif_auto.ps1 "C:\Videos" "C:\ConvertedGifs" 10
```

This example converts videos from `C:\Videos` to `C:\ConvertedGifs`, processing 10 files at a time.

---

### Customization

You can edit the following variables at the top of the script to match your preferences:

```powershell
$fps = 33          # Change frame rate
$scale = 540       # Change output width (height adjusts automatically)
$duration = 5      # Change clip length in seconds
$BatchSize = 20    # Change how many files are processed in parallel
```

For example:

- To make 10-second GIFs, change `$duration = 10`
- To resize to 720 px width, change `$scale = 720`
- To reduce CPU load, lower `$BatchSize` to 5 or 10

---

### Example Output Structure

```
/YourFolderContaingTheVideos/
│
├── mp4_to_gif_auto.ps1
├── video1.mp4
├── video2.mp4
└── gifs/
    ├── video1.gif
    └── video2.gif
```

---

### License

You are free to use, modify, and distribute it with attribution.
