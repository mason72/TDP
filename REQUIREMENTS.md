# Hotfolder Slideshow App - Requirements

## Overview
A macOS desktop application that watches a folder of images and videos and plays them as a fullscreen slideshow. Designed for use on laptops connected to multiple external displays (e.g., retail environments, events, digital signage).

---

## Core Requirements

### 1. Monitor Selection
- On launch, display a list of all connected monitors (name + resolution)
- Allow the user to select which monitor displays the slideshow
- The app's control window stays on the primary display; the slideshow plays fullscreen on the selected monitor
- Detect monitor connect/disconnect events and update the list dynamically
- If the selected monitor is disconnected during playback, pause and prompt the user to select a new monitor

### 2. Media Playback
- **Images:** JPEG, PNG, HEIC, TIFF, BMP, GIF, WebP
- **Videos:** MP4, MOV, M4V (H.264/H.265 codecs via AVFoundation)
- Images display for a configurable duration (default: 8 seconds)
- Videos play in their entirety (audio muted by default, with a toggle to enable)
- Smooth crossfade transition between slides (configurable duration, default: 1 second)
- Content scaled to fill the screen while maintaining aspect ratio (letterbox/pillarbox for non-matching ratios with a configurable background color, default: black)

### 3. Hot Folder Watching
- User selects a folder to watch via a standard macOS folder picker
- Uses macOS FSEvents to detect new/removed/modified files in real-time
- Slideshow updates live — no restart required
- Recursively watches subfolders (configurable: on/off, default: off)
- Ignores hidden files and non-media files
- If a file is removed from the folder, it is removed from the slideshow rotation

### 4. Playback Order & New Content Priority
- Slideshow contents are randomized (shuffled)
- **New content priority:** When a new file is added to the watched folder, it is queued to play next (or after the current slide finishes)
- If multiple new files are added at once, they play in the order they were detected, then the slideshow resumes its randomized rotation
- The random shuffle avoids repeating a slide until all slides have been shown (full-cycle shuffle)
- Re-shuffle when the cycle completes

### 5. Marketing Folder
- Optionally select a second "marketing folder" to watch
- Marketing slides are inserted into the slideshow at a configurable interval: every **N** regular slides, show 1 marketing slide (default: N = 4)
- Marketing slides play in **alphabetical filename order**, cycling back to the beginning when all have been shown
- Marketing folder is also hot-watched — adding/removing files updates the marketing rotation live
- Marketing slides use the same display settings (duration, transitions) as regular slides
- If the marketing folder is empty or not configured, no marketing slides are shown

---

## Suggested Additional Features

### 6. Control Window UI
- Minimal control panel showing:
  - Current slide preview thumbnail
  - Play / Pause / Next / Previous controls
  - Slide counter (e.g., "12 of 48 slides")
  - Status indicator (watching, paused, error)
- Drag-and-drop: drag a folder onto the app window to set it as the watch folder

### 7. Configurable Slide Duration
- Per-file-type duration settings (e.g., images: 8s, but allow override)
- Global duration slider in the control panel (3–60 seconds)

### 8. Keyboard Shortcuts
- **Space:** Play/Pause
- **Right Arrow:** Next slide
- **Left Arrow:** Previous slide
- **F:** Toggle fullscreen on selected monitor
- **M:** Mute/unmute video audio
- **Esc:** Exit fullscreen / stop slideshow
- **Q / Cmd+Q:** Quit app

### 9. Startup & Persistence
- Remember last-used settings on relaunch (watched folder, marketing folder, selected monitor, durations, interval)
- Option to auto-start slideshow on launch (for kiosk/unattended use)

### 10. Error Handling
- Gracefully skip corrupt or unreadable files (log a warning, move to next slide)
- Show a "waiting for content" screen if the watch folder is empty
- Handle edge cases: folder deleted, permissions changed, disk full

### 11. App Metadata
- macOS menu bar app with a proper icon
- Runs in the Dock (not menu-bar-only) for easy access
- About screen with version info

---

## Technical Architecture

### Platform & Framework
- **macOS** native app (minimum macOS 13 Ventura)
- **Swift** with **SwiftUI** for the control window
- **AVFoundation** for video playback
- **NSScreen API** for multi-monitor management
- **FSEvents / DispatchSource** for file system watching
- **NSWindow** for fullscreen slideshow window on the target display

### Project Structure (Planned)
```
HotfolderSlideshow/
├── HotfolderSlideshow.xcodeproj
├── HotfolderSlideshow/
│   ├── App/
│   │   ├── HotfolderSlideshowApp.swift        # App entry point
│   │   └── AppState.swift                      # Global app state (ObservableObject)
│   ├── Views/
│   │   ├── ControlPanel/
│   │   │   ├── ControlPanelView.swift          # Main control window
│   │   │   ├── MonitorPickerView.swift         # Monitor selection UI
│   │   │   ├── FolderPickerView.swift          # Folder selection UI
│   │   │   └── SettingsView.swift              # Duration, interval, etc.
│   │   └── Slideshow/
│   │       ├── SlideshowWindow.swift           # Fullscreen NSWindow on target display
│   │       ├── SlideshowView.swift             # Image/video rendering view
│   │       └── TransitionView.swift            # Crossfade transition logic
│   ├── Models/
│   │   ├── SlideItem.swift                     # Represents a single slide (image or video)
│   │   ├── SlideshowPlaylist.swift             # Manages ordering, shuffle, new-content priority
│   │   └── MarketingPlaylist.swift             # Marketing folder ordering
│   ├── Services/
│   │   ├── FolderWatcher.swift                 # FSEvents wrapper for hot folder
│   │   ├── MediaLoader.swift                   # Async image/video loading & caching
│   │   └── MonitorManager.swift                # Screen detection & management
│   └── Utilities/
│       ├── FileFilterUtility.swift             # Media file type filtering
│       └── UserDefaultsManager.swift           # Settings persistence
└── README.md
```

### Key Design Decisions
1. **Two-window architecture:** Control panel on the primary display, slideshow fullscreen on the selected external display. Both are separate `NSWindow` instances.
2. **Playlist engine:** A dedicated `SlideshowPlaylist` class manages the ordering logic — full-cycle shuffle with new-content priority interrupts. Marketing slides are injected by a counter, not mixed into the shuffle.
3. **Async media loading:** Pre-load the next 2–3 slides in the background for smooth transitions, especially for large images and video files.

---

## Out of Scope (v1)
- Remote control / network API
- Scheduling (play different content at different times)
- Multi-zone layouts (split screen)
- Windows/Linux support
- Cloud folder syncing (Google Drive, Dropbox, etc. — users can use native sync clients)

---

## Open Questions
1. **Video audio:** Should video audio be muted by default, or should there be a global audio on/off toggle? (Current plan: muted by default with toggle)
2. **Subfolder watching:** Should the app recursively watch subfolders by default, or is flat-folder watching sufficient? (Current plan: off by default, configurable)
3. **Transition style:** Crossfade only, or offer multiple transition types (slide, fade to black, etc.)? (Current plan: crossfade only for v1)
4. **Marketing slide duration:** Should marketing slides use the same display duration as regular slides, or have their own configurable duration? (Current plan: same duration)
