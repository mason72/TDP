# Hotfolder Slideshow

A macOS desktop app that watches a folder of images and videos and plays them as a fullscreen slideshow on any connected display. Designed for multi-monitor setups like retail, events, and digital signage.

## Features

- **Multi-monitor support** — select which display shows the slideshow
- **Hot folder watching** — drop files into a folder, they appear in the slideshow immediately
- **Image & video playback** — supports JPEG, PNG, HEIC, MP4, MOV, and more
- **Smart ordering** — randomized shuffle with new-content priority (new files play next)
- **Marketing slides** — optional second folder for marketing content inserted every N slides in alphabetical order
- **Crossfade transitions** — smooth configurable transitions between slides
- **Persistent settings** — remembers folders, display, and preferences between launches
- **Auto-start mode** — for unattended kiosk operation

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15+

## Setup

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you don't have it:
   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open in Xcode:
   ```bash
   open HotfolderSlideshow.xcodeproj
   ```

4. Build and run (Cmd+R)

## Usage

1. **Select a display** — pick which monitor to show the slideshow on
2. **Select a folder** — choose a folder containing images and/or videos
3. **Press Play** — the slideshow starts fullscreen on the selected display
4. **Add/remove files** — the slideshow updates in real-time as files change
5. Optionally set a **marketing folder** to insert marketing slides at regular intervals

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Space | Play / Pause |
| Right Arrow | Next slide |
| Left Arrow | Previous slide |
| Escape | Stop slideshow |
| M | Toggle video audio |

## Project Structure

```
HotfolderSlideshow/
├── App/           # App entry point and central state
├── Models/        # Data models and playlist logic
├── Services/      # Folder watching, media loading, monitor detection
├── Utilities/     # File filtering, settings persistence
└── Views/
    ├── ControlPanel/  # Settings and controls UI
    └── Slideshow/     # Fullscreen slideshow window
```

## Architecture

- **Swift + SwiftUI** for the control panel
- **AppKit (NSWindow)** for precise multi-monitor fullscreen control
- **AVFoundation** for video playback
- **DispatchSource + timer** for file system watching
- **Combine** for reactive data flow between services
