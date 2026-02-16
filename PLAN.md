# Hotfolder Prints - Mac Application Plan

## Overview
A macOS native application that watches a folder for incoming photos (from photo booths, headshot stations, etc.) and automatically composites them into customizable print layouts, then sends them to a selected printer. Designed for event professionals who need a "set it and forget it" printing workflow.

## Tech Stack
- **Language:** Swift
- **UI Framework:** SwiftUI (macOS 13+ Ventura)
- **Image Compositing:** Core Graphics / Core Image
- **Printing:** AppKit NSPrintOperation / CUPS
- **File Watching:** DispatchSource / FSEvents
- **Persistence:** UserDefaults + JSON files for templates
- **Build System:** Xcode / Swift Package Manager

## Architecture

```
HotfolderPrints/
├── HotfolderPrints.xcodeproj/
├── HotfolderPrints/
│   ├── App/
│   │   ├── HotfolderPrintsApp.swift          # App entry point
│   │   └── AppState.swift                     # Global app state (ObservableObject)
│   ├── Models/
│   │   ├── PrintTemplate.swift                # Template model (Codable)
│   │   ├── ImageSlot.swift                    # Individual image slot config
│   │   ├── PrintJob.swift                     # Print job model (pending/complete/failed)
│   │   ├── PrintSize.swift                    # Enum: 4x6, 5x7, 8x10
│   │   └── FitMode.swift                      # Enum: fill, fit, stretch
│   ├── Views/
│   │   ├── MainWindow/
│   │   │   ├── MainView.swift                 # Top-level tabbed/sidebar layout
│   │   │   └── SidebarView.swift              # Navigation sidebar
│   │   ├── Setup/
│   │   │   ├── FolderPickerView.swift         # Watch folder selection
│   │   │   ├── PrinterPickerView.swift        # System printer selection
│   │   │   └── EventSettingsView.swift        # Copies, print size, general settings
│   │   ├── TemplateEditor/
│   │   │   ├── TemplateEditorView.swift       # Main WYSIWYG editor
│   │   │   ├── CanvasView.swift               # Live preview canvas (actual print proportions)
│   │   │   ├── SlotConfigPanel.swift          # Per-slot settings (size, position, rotation, crop)
│   │   │   ├── LayersPanelView.swift          # Background, image slots, overlay layer ordering
│   │   │   ├── TemplateGalleryView.swift      # Browse/select/save templates
│   │   │   └── TextOverlayEditor.swift        # Add/edit text overlays
│   │   ├── EventDashboard/
│   │   │   ├── DashboardView.swift            # Live event status (running/paused, stats)
│   │   │   ├── PrintQueueView.swift           # Pending/active print jobs
│   │   │   └── IncomingPhotosView.swift       # Photos waiting to fill slots
│   │   └── PrintBrowser/
│   │       ├── PrintBrowserView.swift         # Grid of all completed prints
│   │       ├── PrintDetailView.swift          # Full-size preview + reprint controls
│   │       └── ReprintSheet.swift             # Quick reprint with copy count
│   ├── Services/
│   │   ├── FolderWatcher.swift                # FSEvents-based folder monitoring
│   │   ├── ImageCompositor.swift              # Core Graphics compositing engine
│   │   ├── PrintService.swift                 # Printer discovery, print job execution
│   │   ├── PrintQueueManager.swift            # Queue management, retry logic
│   │   ├── TemplateManager.swift              # Load/save/delete templates
│   │   └── DuplicateDetector.swift            # Hash-based duplicate file detection
│   ├── Utilities/
│   │   ├── ImageUtils.swift                   # Image loading, resizing, rotation helpers
│   │   ├── ColorProfileManager.swift          # ICC profile handling
│   │   └── FileFilterUtility.swift            # Supported format filtering
│   └── Resources/
│       ├── Assets.xcassets/                    # App icons, accent colors
│       ├── DefaultTemplates/                  # Built-in template JSON files
│       └── SampleOverlays/                    # Example overlay PNGs
```

## Data Models

### PrintTemplate (Codable, Identifiable)
- `id: UUID`
- `name: String`
- `printSize: PrintSize` — enum: 4x6, 5x7, 8x10
- `imageSlots: [ImageSlot]` — 1 to 4 slots
- `backgroundImage: URL?` — optional background image
- `overlayImage: URL?` — optional overlay PNG (rendered on top)
- `textOverlays: [TextOverlay]` — positioned text elements
- `backgroundColor: Color` — default white
- `isDefault: Bool` — built-in vs user-created

### ImageSlot (Codable, Identifiable)
- `id: UUID`
- `rect: CGRect` — position and size (in percentage of canvas, 0-1 range)
- `rotation: Double` — degrees
- `cornerRadius: Double`
- `fitMode: FitMode` — fill (crop), fit (letterbox), stretch
- `border: SlotBorder?` — optional border (color, width)

### TextOverlay (Codable, Identifiable)
- `id: UUID`
- `text: String`
- `position: CGPoint` — percentage-based
- `fontSize: Double`
- `fontName: String`
- `color: Color`
- `rotation: Double`

### PrintJob (Identifiable, ObservableObject)
- `id: UUID`
- `template: PrintTemplate`
- `sourceImages: [URL]`
- `compositedImage: NSImage?` — the final rendered output
- `status: PrintJobStatus` — enum: pending, printing, completed, failed
- `copies: Int`
- `createdAt: Date`
- `completedAt: Date?`
- `errorMessage: String?`

### PrintSize (enum)
- `fourBySix` — 4" × 6" (1200 × 1800 px at 300 DPI)
- `fiveBySeven` — 5" × 7" (1500 × 2100 px at 300 DPI)
- `eightByTen` — 8" × 10" (2400 × 3000 px at 300 DPI)
- Properties: `widthInches`, `heightInches`, `pixelWidth`, `pixelHeight`, `aspectRatio`

## Core Workflows

### 1. Setup Flow
1. User selects a **watch folder** (where photo booth drops images)
2. User selects a **printer** from system printers list
3. User selects or creates a **print template** (layout)
4. User sets **default copies** per print (1-10)
5. User sets **print size** (4x6, 5x7, 8x10)

### 2. Template Editor (WYSIWYG)
- Canvas shows exact proportions of selected print size
- User adds 1-4 image slots by clicking "Add Slot" button
- Each slot is a draggable, resizable rectangle on the canvas
- Slot handles for resize, rotation knob for rotation
- Right panel shows selected slot properties (exact values for size, position, rotation, fit mode)
- User can set a background image (fills entire canvas behind slots)
- User can set an overlay PNG (renders on top of everything)
- User can add text overlays with font, size, color, position
- Live preview with sample images so user can see exactly what the print will look like
- Save template with a name; load from template gallery

### 3. Auto-Print Event Flow
1. User clicks **"Start Event"** button
2. FolderWatcher begins monitoring the watch folder
3. New image detected → added to incoming queue
4. When enough images accumulate to fill all slots in the template:
   - Images are assigned to slots in order received
   - ImageCompositor renders the final print at 300 DPI
   - Composited image is saved to a session output folder
   - PrintJob is created and sent to PrintQueueManager
   - PrintService sends to selected printer with configured copies
5. Dashboard shows live stats: photos received, prints made, prints pending
6. User can pause/resume the event at any time

### 4. Print Browser & Reprinting
- Grid view of all composited prints from the current session
- Click any print to see full-size preview
- "Reprint" button opens a sheet to set copy count (1-99)
- Sends new print job to queue immediately
- Shows print history with timestamps

## Default Templates

### 1. "Classic Single" (1 image)
- Print size: 4x6
- One image slot filling the entire canvas
- No background, no overlay
- Fit mode: Fill

### 2. "Side by Side" (2 images)
- Print size: 4x6
- Two equal image slots arranged horizontally
- Small gap between them
- White background

### 3. "Photo Strip" (3 images)
- Print size: 4x6 (portrait orientation)
- Three equal image slots stacked vertically
- Small gap between each
- White background

### 4. "Grid" (4 images)
- Print size: 4x6
- Four equal image slots in 2x2 grid
- Small gap between slots
- White background

### 5. "Headshot with Branding" (1 image)
- Print size: 5x7
- One large image slot (centered, with margins)
- Space at bottom for text overlay (event name/date)
- White background

### 6. "Event Collage" (4 images)
- Print size: 8x10
- Four varied-size slots in artistic arrangement
- One large hero image, three smaller accent images

## Implementation Phases

### Phase 1: Project Foundation
- Create Xcode project structure
- Define all data models (PrintTemplate, ImageSlot, PrintJob, PrintSize, etc.)
- Set up AppState as the central ObservableObject
- Implement TemplateManager (save/load JSON templates)
- Create default templates
- Build main window shell with sidebar navigation

### Phase 2: Template Editor (WYSIWYG)
- Build CanvasView with correct print size proportions
- Implement draggable, resizable image slot rectangles on canvas
- Add rotation handles to slots
- Build SlotConfigPanel for precise property editing
- Implement background image picker and preview
- Implement overlay image picker and preview
- Add text overlay creation and editing
- Template save/load UI (TemplateGalleryView)
- Live preview with sample/placeholder images

### Phase 3: Printer & Folder Setup
- FolderPickerView with system folder dialog
- PrinterPickerView listing system printers (via CUPS/NSPrinter)
- EventSettingsView for copies, print size configuration
- Persist settings with UserDefaults

### Phase 4: Core Engine
- FolderWatcher service (FSEvents-based, filters for supported image formats)
- DuplicateDetector using file hash comparison
- ImageCompositor — Core Graphics rendering engine:
  - Render at 300 DPI for target print size
  - Draw background image (scaled to fill)
  - Draw each image slot with position, size, rotation, fit mode, corner radius, border
  - Draw overlay PNG on top
  - Draw text overlays
  - Export as high-quality TIFF/PNG
- PrintService — discover printers, send print jobs via NSPrintOperation
- PrintQueueManager — sequential job processing, retry on failure

### Phase 5: Event Dashboard & Live Operation
- DashboardView showing event status, live counters
- IncomingPhotosView showing photos waiting to fill slots
- PrintQueueView showing active/pending/completed jobs
- Start/Pause/Stop event controls
- Auto-print orchestration: watch → accumulate → composite → print

### Phase 6: Print Browser & Reprinting
- PrintBrowserView — grid of all composited prints
- PrintDetailView — full-size preview
- ReprintSheet — select copies and reprint
- Print history log with timestamps and status

### Phase 7: Polish & Additional Features
- Crop/fit mode previews in template editor
- Border/margin controls per slot
- Color profile support (sRGB, printer ICC profiles)
- Print history/log export
- Keyboard shortcuts
- Error handling and user notifications
- App icon and visual polish
- Edge cases: corrupt files, printer offline, disk full

## Key Technical Decisions

1. **Percentage-based positioning** — Slot positions stored as 0-1 percentages so templates scale across print sizes
2. **300 DPI rendering** — All compositing done at print resolution, not screen resolution
3. **Sequential print queue** — One job at a time to avoid overwhelming the printer
4. **File hashing for deduplication** — MD5/SHA256 hash of file content to detect duplicates
5. **JSON template format** — Human-readable, easy to share between machines
6. **Session-based output** — Each event session saves composited images to a dated folder for easy browsing and reprinting
7. **Combine-based reactivity** — FolderWatcher publishes new files, queue manager subscribes and orchestrates
