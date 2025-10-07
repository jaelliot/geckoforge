# OBS Studio NVENC Setup

## How It Works

OBS Studio (Flatpak) uses the **host** NVIDIA driver for hardware encoding. No container GPU passthrough needed.

## Prerequisites

1. **NVIDIA driver installed**: `nvidia-smi` should show your GPU
2. **OBS installed**: `flatpak install flathub com.obsproject.Studio`

## Verification

### Step 1: Check driver
```bash
nvidia-smi
# Should show driver version 535+ for modern NVENC support
```

### Step 2: Launch OBS
```bash
flatpak run com.obsproject.Studio
```

### Step 3: Check encoder availability
1. Go to **Settings** → **Output**
2. Click **Streaming** tab
3. Under **Encoder**, you should see:
   - `NVIDIA NVENC H.264` (new)
   - `NVIDIA NVENC H.264 (FFmpeg)` (older but works)

If not present, check troubleshooting below.

### Step 4: Test recording
1. Add a source (e.g., Display Capture)
2. Click **Start Recording**
3. Record for 10 seconds
4. Check file: should be small (hardware encoding is efficient)
5. In OBS **Stats**, CPU usage should be low (~5-10% vs 50%+ for x264)

## Troubleshooting

### NVENC not visible in encoder list

**Possible causes**:
1. **Driver too old**: Update via `sudo zypper up nvidia-*`
2. **Flatpak permissions**: Check if Flatpak can access GPU
   ```bash
   flatpak override --user --device=all com.obsproject.Studio
   ```
3. **Wayland quirks**: Try running OBS on Xorg session instead (logout → select Xorg at login)

### "Failed to open NVENC codec"

**Fix**: Restart OBS after updating driver:
```bash
flatpak kill com.obsproject.Studio
flatpak run com.obsproject.Studio
```

### Check OBS logs

```bash
# View logs
flatpak run com.obsproject.Studio --verbose

# Or check saved logs
~/.var/app/com.obsproject.Studio/config/obs-studio/logs/
```

## Recommended Settings

For streaming/recording:
- **Encoder**: NVIDIA NVENC H.264
- **Rate Control**: CBR (constant bitrate)
- **Bitrate**: 6000 Kbps for 1080p60 (adjust based on internet)
- **Preset**: Quality (slower = better quality, but NVENC is fast anyway)
- **Profile**: high
- **GPU**: 0 (auto-selects your GPU)

## Performance Notes

- NVENC offloads encoding to GPU → CPU stays free for other tasks
- Latency is lower than x264 CPU encoding
- Quality is comparable to x264 "veryfast" preset
- For archival quality, use x264 "slow" or "slower" (but CPU-intensive)
