# PDFViewer iOS - Comprehensive Technical Documentation

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Features & Functionality](#features--functionality)
- [Data Layer](#data-layer)
- [Business Logic Layer](#business-logic-layer)
- [Presentation Layer](#presentation-layer)
- [Annotation System](#annotation-system)
- [File Management](#file-management)
- [Theming & Design System](#theming--design-system)
- [Technical Implementation Details](#technical-implementation-details)

---

## Overview

**PDFViewer** is a high-performance, feature-rich PDF viewer and annotation application for iOS. Built with SwiftUI and following modern iOS development best practices, it provides a seamless experience for viewing, annotating, and managing PDF documents.

### Key Technical Highlights
- **Architecture**: MVVM (Model-View-ViewModel) with Repository Pattern
- **UI Framework**: SwiftUI with UIKit integration (PDFKit, PencilKit)
- **Data Persistence**: Core Data
- **Reactive Programming**: Combine framework
- **Platform**: iOS (SwiftUI-based)
- **Drawing Engine**: PencilKit for annotations

---

## Architecture

### Design Patterns

#### 1. MVVM (Model-View-ViewModel)
The application strictly follows the MVVM pattern:
- **Models**: Data structures (`PDFModelData`, `FolderModelData`)
- **Views**: SwiftUI views (`PDFListView`, `PDFViewerView`)
- **ViewModels**: Business logic (`PDFListViewModel`, `PDFViewerViewModel`)

#### 2. Repository Pattern
`PDFRepository` abstracts data access, providing a clean interface between business logic and data persistence:
```
ViewModel → Repository (Protocol) → Core Data Store
```

#### 3. Feature-Based Organization
```
PDFViewer/
├── Features/
│   ├── PdfList/          # PDF library feature
│   ├── Viewer/           # PDF viewing feature
│   └── Components/       # Shared UI components
├── Data/                 # Data models
├── Repository/           # Data access layer
├── Core Data/            # Persistence layer
├── Core/                 # Theme, strings, design system
├── Drawing/              # Annotation tools
└── Utility/              # Helpers and extensions
```

---

## Features & Functionality

### 1. PDF Library Management

#### PDF List View (`PDFListView`, `PDFListViewModel`)
**Features:**
- Display all imported PDFs with metadata (title, author, page count, thumbnail)
- Multiple view modes:
  - **All PDFs**: Shows entire library
  - **Favorites**: Filtered view of favorited documents
  - **Recent**: PDFs sorted by last opened time
  - **Folders**: Custom user-created folders for organization
- Search functionality (by title and author)
- Sort and filter options

**Key Functions:**
```swift
// PDFListViewModel.swift
- loadPDFs() → AnyPublisher<[PDFModelData], Error>
- toggleFavorite(for: PDFModelData)
- deletePdfs(_ pdfs: [PDFModelData])
- updateSelection(_ selection: PDFListSelection)
- applySelection() // Filters/sorts based on current selection
```

#### PDF Import (`PDFImportViewModel`)
**Features:**
- Import multiple PDFs from device storage
- Duplicate detection (prevents re-importing existing files)
- Background processing to avoid UI freezes
- Progress tracking during import
- Automatic thumbnail generation
- Metadata extraction (title, author)

**Key Functions:**
```swift
// PDFImportViewModel.swift
- importPDFsAndForget(urls: [BookmarkDataClass])
- processPDFs() // Background processing of PDF imports
```

**Implementation Details:**
- Uses security-scoped bookmark data for file access persistence
- Generates unique keys for each PDF using file metadata
- Extracts first page for thumbnail generation
- Stores PDF references (not copies) using bookmark data

#### Folder Management
**Features:**
- Create custom folders for organizing PDFs
- Move PDFs between folders (single or batch)
- Delete folders
- Navigate into folders to view contained PDFs
- Visual folder representation with color coding

**Key Functions:**
```swift
// PDFListViewModel.swift
- createFolder(title: String)
- deleteFolder(_ folder: FolderModelData)
- movePDF(_ pdf: PDFModelData, to folder: FolderModelData?)
- movePDFs(_ pdfs: [PDFModelData], to folder: FolderModelData?)
```

#### Multi-Select Mode
**Features:**
- Select multiple PDFs for batch operations
- Batch delete
- Batch move to folder
- Visual selection indicators

**Key Functions:**
```swift
// PDFListViewModel.swift
- enterMultiSelectMode(with pdfKey: String?)
- exitMultiSelectMode()
- toggleSelection(for pdfKey: String)
- deleteSelectedPDFs()
- moveSelectedPDFs(to folder: FolderModelData?)
```

#### Swipe Actions
- **Delete**: Swipe left to delete PDF
- **Move**: Swipe to move PDF to folder

---

### 2. PDF Viewing

#### PDF Viewer (`PDFViewerView`, `PDFViewerViewModel`)
**Features:**
- Native PDFKit integration for high-fidelity rendering
- Multiple display modes:
  - Single page
  - Continuous scroll
  - Two-up (side by side)
- Display directions (horizontal/vertical)
- Zoom controls (pinch, buttons)
- Page navigation with progress indicator
- Resume last read position
- Brightness adjustment overlay
- Reading modes for different viewing experiences

**Key Functions:**
```swift
// PDFViewerViewModel.swift
- zoomIn() / zoomOut()
- preparePageProgressText()
- goToPage() // Resume last position
- updateLastOpenedtime()
- saveLastOpenedPageNumberInDb()
```

#### Reading Modes (`ReadingMode`)
Multiple modes for different reading preferences:
- **Normal**: Standard viewing
- **Sepia**: Warm tone for comfortable reading
- **Night**: Dark mode optimized
- Custom brightness control

**Implementation:**
```swift
// PDFSettings.swift
enum ReadingMode: String {
    case normal
    case sepia  
    case night
}
```

#### Page Tracking & Resume
- Automatically saves last viewed page
- Debounced page change tracking (saves after 5 seconds of inactivity)
- Instant resume when reopening a document
- Visual page progress indicator (e.g., "15/120")

---

### 3. Annotation System

#### Overview
The annotation system uses **PencilKit** for natural drawing and writing on PDFs, with custom persistence to Core Data.

#### Drawing Tools (`DrawingToolManager`, `PDFAnnotationSetting`)
**Available Tools:**
1. **Pen**: Freehand drawing with customizable color and width
2. **Pencil**: Sketching tool (lighter strokes)
3. **Highlighter**: Semi-transparent highlighting
4. **Text**: Add text annotations
5. **Eraser**: Remove annotations

**Tool Settings:**
```swift
// PDFAnnotationSetting
struct PDFAnnotationSetting {
    var annotationTool: AnnotationTool  // pen, pencil, highlighter, text, eraser, none
    var lineWidth: CGFloat              // Stroke thickness
    var color: UIColor                  // Drawing color
    var isExpandable: Bool              // Can customize settings
}
```

**Color Options:**
8 predefined colors: Red, Green, Blue, Yellow, Orange, Purple, Black, Gray

#### Annotation Manager (`PDFAnnotationManager`)
**Responsibilities:**
- Serialize PencilKit drawings to binary data
- Persist annotations to Core Data
- Load annotations from database into memory cache
- Manage per-page annotation data

**Key Functions:**
```swift
// PDFAnnotationManager.swift
- getSerializedAnnotations(for pdfURL: URL) -> Data?
- loadAnnotations(from data: Data?, for pdfURL: URL)
- syncViewsToCache(canvasViews: [Int: PKCanvasView], pdfURL: URL)
- getDrawing(for pageIndex: Int, pdfURL: URL) -> PKDrawing?
- updateCache(for pageIndex: Int, canvasView: PKCanvasView, pdfURL: URL)
```

**Persistence Strategy:**
1. Each PDF page can have its own annotation layer
2. Annotations stored as serialized `PKDrawing` objects
3. Cached in memory during editing: `[URL: [PageIndex: Data]]`
4. Saved to Core Data on:
   - Page navigation (debounced)
   - Tool changes
   - App backgrounding
   - Document closure

#### Annotation Export
**Flattened PDF Export:**
```swift
// Export PDF with annotations permanently merged
func exportFlattenedPDF(
    pdfDocument: PDFDocument,
    canvasViews: [Int: PKCanvasView],
    pdfView: PDFView,
    originalURL: URL
) -> URL?
```
Creates a new PDF with all annotations rendered directly into the document (non-editable).

#### Annotation UI Components
1. **AnnotationSettingsView**: Tool selection and color picker
2. **AnnotationListControllerView**: List all annotations in document
3. **SingleAnnotationItemView**: Individual annotation preview

#### Undo/Redo System
- Custom undo manager for annotation operations
- Per-page undo stacks
- Integrated with PencilKit's native undo
- Visual undo/redo button states

**Implementation:**
```swift
// PDFKitView.swift
private let annotationUndoManager = UndoManager()

// In PDFViewerViewModel
@Published var canUndo: Bool = false
@Published var canRedo: Bool = false

func undo() { actions.undo() }
func redo() { actions.redo() }
```

---

### 4. File Management

#### Security-Scoped Bookmarks
PDFs are NOT copied into app storage. Instead, the app uses **security-scoped bookmark data** to maintain access to files in their original locations.

**Implementation:**
```swift
// URL+Extensions.swift
extension URL {
    func toBookmarData() -> Data? {
        try? self.bookmarkData(
            options: .minimalBookmark, 
            includingResourceValuesForKeys: nil, 
            relativeTo: nil
        )
    }
}

// PDFModelData.swift
func resolveSecureURL() -> URL? {
    guard let bookmarkData = bookmarkData else { return nil }
    var isStale = false
    let url = try? URL(
        resolvingBookmarkData: bookmarkData, 
        options: [], 
        relativeTo: nil, 
        bookmarkDataIsStale: &isStale
    )
    if url?.startAccessingSecurityScopedResource() == true {
        return url
    }
    return nil
}
```

**Lifecycle:**
1. User selects PDF from Files app
2. App creates bookmark data
3. Stores bookmark in Core Data
4. On access: Resolve bookmark → Get URL → Start security-scoped access
5. After use: Stop security-scoped access

#### PDF Metadata Extraction
```swift
// PDFModelData.swift
func decomposeBookmarkData() {
    guard let url = resolveSecureURL() else { return }
    defer { url.stopAccessingSecurityScopedResource() }
    
    guard let document = PDFDocument(url: url) else { return }
    
    // Extract metadata
    title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String 
        ?? url.lastPathComponent
    author = document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String 
        ?? "Unknown"
    totalPageCount = document.pageCount
    
    // Generate thumbnail
    let page = document.page(at: 0)
    thumbImage = page?.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox)
}
```

---

## Data Layer

### Core Data Schema

#### PDFEntity
Stores PDF document references and metadata.

**Attributes:**
```swift
@NSManaged public var key: String                  // Unique identifier
@NSManaged public var bookmarkData: Data           // Security-scoped bookmark
@NSManaged public var annotationData: Data?        // Serialized annotations
@NSManaged public var isFavourite: Bool            // Favorite status
@NSManaged public var lastOpenedPage: Int16        // Last viewed page
@NSManaged public var lastOpenTime: Date?          // Last access timestamp
```

#### FolderEntity
Stores user-created folders for organization.

**Attributes:**
```swift
@NSManaged public var id: String                   // Unique folder ID
@NSManaged public var title: String                // Folder name
@NSManaged public var pdfIds: String?              // Comma-separated PDF keys
@NSManaged public var createdAt: Date              // Creation timestamp
@NSManaged public var updatedAt: Date              // Last modification
```

### Data Models

#### PDFModelData
In-memory representation of a PDF document.

**Properties:**
```swift
class PDFModelData: Identifiable {
    let id: String                       // UI identifier
    let key: String                      // Unique PDF key
    var urlPath: String?                 // Resolved file path
    var title: String?                   // Document title
    var author: String?                  // Document author
    let bookmarkData: Data?              // Security bookmark
    var annotationdata: Data?            // Annotation data
    var isFavorite: Bool                 // Favorite flag
    var lastOpenedPage: Int              // Resume page
    var lastOpenTime: Date?              // Last opened
    var thumbImage: UIImage?             // Thumbnail image
    var totalPageCount: Int              // Total pages
}
```

**Key Methods:**
```swift
- decomposeBookmarkData()                 // Extract metadata from PDF
- resolveSecureURL() -> URL?              // Get file URL
- toCoereDataModel() -> PDFCoreDataModel  // Convert to Core Data
```

#### FolderModelData
In-memory representation of a folder.

**Properties:**
```swift
class FolderModelData: Identifiable {
    let id: String                    // Unique identifier
    var title: String                 // Folder name
    var pdfIds: [String]              // Contained PDF keys
    var createdAt: Date               // Creation date
    var updatedAt: Date               // Last update
}
```

### Repository Layer (`PDFRepository`)

**Protocol:**
```swift
protocol PDFRepositoryProtocol {
    // PDF Operations
    func insert(pdfDatas: [PDFModelData]) -> AnyPublisher<Bool, Error>
    func retrieve() -> AnyPublisher<[PDFModelData], Error>
    func getSingleData(pdfKey: String) -> AnyPublisher<PDFModelData, Error>
    func update(updatedPdfData: PDFModelData) -> AnyPublisher<PDFModelData, Error>
    func delete(pdfKey: String) -> AnyPublisher<Bool, Error>
    
    // Folder Operations
    func insertFolders(folders: [FolderModelData]) -> AnyPublisher<Bool, Error>
    func retrieveFolders() -> AnyPublisher<[FolderModelData], Error>
    func updateFolder(updatedFolder: FolderModelData) -> AnyPublisher<FolderModelData, Error>
    func deleteFolder(folderId: String) -> AnyPublisher<Bool, Error>
}
```

**Implementation:** `PDFLocalRepositoryImpl`
- Converts between domain models and Core Data entities
- Uses Combine for reactive data flow
- Handles all Core Data operations

### Core Data Store (`PDFLocalDataStore`)

Low-level Core Data operations with Combine publishers.

**Key Functions:**
```swift
// Generic CRUD operations
- insert<T: NSManagedObject>(entity: T) -> AnyPublisher<Bool, Error>
- retrieve<T: NSManagedObject>() -> AnyPublisher<[T], Error>
- update<T: NSManagedObject>(updatedData: T) -> AnyPublisher<T, Error>
- delete(entity: NSManagedObject) -> AnyPublisher<Bool, Error>
- filter(parameters: [String: Any]) -> AnyPublisher<[PDFEntity], Error>
```

---

## Business Logic Layer

### PDFListViewModel

**Responsibilities:**
- Manages PDF library state
- Handles folder operations
- Implements filtering and sorting logic
- Coordinates import operations
- Manages multi-select mode

**Published Properties:**
```swift
@Published var currentSelection: PDFListSelection = .all
@Published var allPdfModels: [PDFModelData] = []
@Published var visiblePdfModels: [PDFModelData] = []  // Filtered/sorted
@Published var folders: [FolderModelData] = []
@Published var isMultiSelectMode = false
@Published var selectedPDFKeys: Set<String> = []
@Published var isShowingImportProgress = false
@Published var importViewModel: PDFImportViewModel?
@Published var toastMessage: String?
@Published var searchText: String = ""
```

**Selection System:**
```swift
enum PDFListSelection {
    case all                          // All PDFs
    case favorite                     // Favorites only
    case recent                       // Recent PDFs
    case folder(FolderModelData)      // Specific folder
}
```

**Filtering Logic:**
```swift
private func applySelection() {
    let filteredModels: [PDFModelData]
    switch currentSelection {
    case .all:
        filteredModels = allPdfModels
    case .favorite:
        filteredModels = allPdfModels.filter { $0.isFavorite }
    case .recent:
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        filteredModels = allPdfModels.filter { 
            ($0.lastOpenTime ?? .distantPast) > cutoffDate 
        }
    case .folder(let folder):
        filteredModels = allPdfModels.filter { 
            folder.pdfIds.contains($0.key) 
        }
    }
    
    visiblePdfModels = filterBySearchText(filteredModels)
}
```

**Search Implementation:**
```swift
private func filterBySearchText(_ models: [PDFModelData]) -> [PDFModelData] {
    if searchText.isEmpty { return models }
    return models.filter { pdf in
        (pdf.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
        (pdf.author?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
}
```

### PDFViewerViewModel

**Responsibilities:**
- Manages PDF viewing state
- Handles annotation tool selection
- Controls zoom and navigation
- Saves viewing progress
- Manages reading modes and brightness

**Published Properties:**
```swift
@Published var pdfData: PDFModelData
@Published var currentPDF: URL?
@Published var annotationSettingData: PDFAnnotationSetting
@Published var lastDrawingColor: UIColor = .red
@Published var zoomScale: CGFloat = 1.0
@Published var readingMode: ReadingMode = .normal
@Published var showPalette = false
@Published var showControls = true
@Published var showBrightnessControls = false
@Published var actions = PDFKitViewActions()
@Published var settings = PDFSettings()
@Published var displayBrightness: CGFloat = 100
@Published var pageProgressText: String = ""
@Published var canUndo: Bool = false
@Published var canRedo: Bool = false
```

**Annotation Tool Selection:**
```swift
func selectTool(_ setting: PDFAnnotationSetting, manager: DrawingToolManager) {
    withAnimation {
        let newSetting = (annotationSettingData.annotationTool == setting.annotationTool) 
            ? .noneData()   // Deselect if clicking same tool
            : setting
        annotationSettingData = newSetting
        
        // Remember last color for next use
        if newSetting.annotationTool != .none && newSetting.annotationTool != .eraser {
            lastDrawingColor = newSetting.color
        }
        
        manager.selectePdfdSetting = newSetting
        manager.updatePdfSettingData(newSetting: newSetting)
    }
}
```

**Debounced Page Saving:**
```swift
private let pageChangeSubject = PassthroughSubject<Int, Never>()

init(...) {
    // Debounce page changes to avoid excessive DB writes
    pageChangeSubject
        .debounce(for: .seconds(5), scheduler: RunLoop.main)
        .sink { [weak self] page in
            self?.saveLastOpenedPageNumberInDb()
        }
        .store(in: &cancellables)
}
```

**Brightness Overlay:**
```swift
func getBrightnessOpacity() -> CGFloat {
    let brightnessPercentage: CGFloat = displayBrightness / 100
    let brightness = 1.0 - brightnessPercentage
    UserDefaultsHelper.shared.savedBrightness = displayBrightness
    return brightness
}
```

### PDFImportViewModel

**Responsibilities:**
- Process multiple PDF imports
- Prevent duplicate imports
- Extract metadata and thumbnails
- Report import progress
- Handle background processing

**Key Implementation:**
```swift
class PDFImportViewModel: ObservableObject {
    @Published var totalFiles: Int
    @Published var processedFiles: Int = 0
    @Published var isComplete: Bool = false
    
    private var repository: PDFRepositoryProtocol
    private var existingKeys: Set<String>  // For duplicate detection
    
    func processPDFs() {
        // Process PDFs in background to avoid UI freezes
        DispatchQueue.global(qos: .userInitiated).async {
            for bookmarkData in self.bookmarkDatas {
                // Generate key from bookmark
                let key = self.generatePDFKey(from: bookmarkData)
                
                // Skip duplicates
                guard !self.existingKeys.contains(key) else {
                    self.updateProgress()
                    continue
                }
                
                // Create PDF model
                let pdfModel = PDFModelData(
                    key: key,
                    bookmarkData: bookmarkData.data,
                    ...
                )
                
                // Save to repository
                self.repository.insert(pdfDatas: [pdfModel])
                self.updateProgress()
            }
            
            DispatchQueue.main.async {
                self.isComplete = true
            }
        }
    }
}
```

---

## Presentation Layer

### Main Views

#### 1. PDFListView
Main library interface showing all PDFs.

**UI Components:**
- Navigation bar with title and import button
- Search bar (collapsible)
- Filter segments (All, Favorites, Recent, Folders)
- PDF list with SwiftUI `List`
- Empty state view
- Toast notifications
- Import progress overlay

**Structure:**
```swift
struct PDFListView: View {
    @StateObject var viewModel: PDFListViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $viewModel.searchText)
                
                // Filter segments
                FilterSegmentView(selection: $viewModel.currentSelection)
                
                // PDF List
                if viewModel.visiblePdfModels.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(viewModel.visiblePdfModels) { pdf in
                            PDFListItemView(pdf: pdf, viewModel: viewModel)
                                .swipeActions { ... }
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingImportProgress) {
                PDFImportView(viewModel: viewModel.importViewModel)
            }
        }
    }
}
```

#### 2. PDFListItemView
Individual PDF row in the list.

**Display:**
- Thumbnail (100x140)
- Title and author
- Page count indicator
- Favorite button
- Navigation chevron
- Selection indicator (multi-select mode)

**Swipe Actions:**
```swift
.swipeActions(edge: .trailing) {
    Button(role: .destructive) {
        viewModel.deletePdfs([pdf])
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
.swipeActions(edge: .leading) {
    Button {
        // Show folder picker
    } label: {
        Label("Move", systemImage: "folder")
    }
}
```

#### 3. PDFViewerView
Full-screen PDF viewer with annotations.

**Layout:**
```swift
struct PDFViewerView: View {
    @StateObject var viewModel: PDFViewerViewModel
    @StateObject var drawingToolManager = DrawingToolManager.dummyData()
    
    var body: some View {
        ZStack {
            // PDF rendering layer
            PDFKitView(
                pdfURL: viewModel.currentPDF,
                settings: viewModel.settings,
                mode: $viewModel.annotationSettingData,
                actions: viewModel.actions
            )
            
            // Brightness overlay
            if viewModel.showBrightnessControls {
                Color.black.opacity(viewModel.getBrightnessOpacity())
            }
            
            // Reading mode overlay (sepia, etc.)
            if viewModel.readingMode != .normal {
                ReadingModeOverlay(mode: viewModel.readingMode)
            }
            
            // Controls overlay
            VStack {
                // Top toolbar
                HStack {
                    BackButton()
                    PageProgressText(text: viewModel.pageProgressText)
                    MoreOptionsMenu()
                }
                
                Spacer()
                
                // Bottom annotation toolbar
                if viewModel.showControls {
                    AnnotationToolbar(
                        viewModel: viewModel,
                        toolManager: drawingToolManager
                    )
                }
            }
        }
        .navigationBarHidden(true)
    }
}
```

#### 4. PDFKitView (UIViewRepresentable)
Bridges UIKit PDFView and PencilKit to SwiftUI.

**Architecture:**
```swift
struct PDFKitView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        
        // PDF view layer
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: pdfURL)
        container.addSubview(pdfView)
        
        // Canvas container for annotations
        let canvasContainer = UIView()
        canvasContainer.isUserInteractionEnabled = false  // Initially
        container.addSubview(canvasContainer)
        
        // Setup coordinator
        context.coordinator.pdfView = pdfView
        context.coordinator.canvasContainerView = canvasContainer
        context.coordinator.setup()
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update tool mode, zoom, etc.
        context.coordinator.updateTool(mode)
    }
}
```

**Coordinator:**
```swift
class Coordinator: NSObject, PKCanvasViewDelegate {
    var pdfView: PDFView?
    var canvasContainerView: UIView?
    var canvasViews: [Int: UndoableCanvasView] = [:]  // Page-specific canvases
    
    private let annotationManager = PDFAnnotationManager()
    private let annotationUndoManager = UndoManager()
    
    // Dynamically create canvas views for visible pages
    @objc func updateCanvasFrames() {
        guard let pdfView = pdfView, let document = pdfView.document else { return }
        
        let visiblePages = pdfView.visiblePages
        let visiblePageIndices = visiblePages.compactMap { 
            document.index(for: $0) 
        }
        
        // Remove canvases for non-visible pages (memory optimization)
        for (pageIndex, canvas) in canvasViews {
            if !visiblePageIndices.contains(pageIndex) {
                canvas.removeFromSuperview()
                canvasViews.removeValue(forKey: pageIndex)
            }
        }
        
        // Create/update canvases for visible pages
        for pageIndex in visiblePageIndices {
            if canvasViews[pageIndex] == nil {
                let canvas = createCanvasView(for: pageIndex)
                canvasViews[pageIndex] = canvas
            }
            updateCanvasFrame(for: pageIndex)
        }
    }
}
```

#### 5. AnnotationSettingsView
Floating toolbar for annotation tools.

**UI Elements:**
- Tool buttons (Pen, Pencil, Highlighter, Text, Eraser)
- Color picker (when tool selected)
- Line width slider (for applicable tools)
- Undo/Redo buttons

**Tool Selection:**
```swift
ForEach(toolManager.pdfSettings, id: \.annotationTool) { setting in
    ToolButton(
        setting: setting,
        isSelected: viewModel.annotationSettingData.annotationTool == setting.annotationTool,
        action: {
            viewModel.selectTool(setting, manager: toolManager)
        }
    )
}
```

### Shared UI Components

#### FilterSegmentView
Segmented control for switching between All/Favorites/Recent/Folders.

#### FolderPickerView
Bottom sheet for selecting a folder when moving PDFs.

#### EmptyStateView
Placeholder shown when no PDFs match current filter.

#### PDFListHeaderView
Section header for grouped lists (e.g., "Folders", "PDFs").

#### BrightnessSettingPopupView
Slider control for adjusting screen brightness overlay.

#### CustomSliderView
Reusable slider component with custom styling.

#### ControlButton
Custom button style used throughout the app.

---

## Theming & Design System

### Color System (`AppColors`)
Centralized color definitions with automatic dark mode support.

**Categories:**
```swift
// Backgrounds
- background          // Primary app background
- surface             // Card/surface background
- surfaceSecondary    // Grouped content background
- surfaceLight        // Toolbar background

// Brand Colors
- primary             // System blue
- accent              // Accent blue
- success, warning, error

// Text Colors
- textPrimary         // Primary label
- textSecondary       // Secondary label
- textTertiary        // Tertiary label
- onPrimary           // Text on colored backgrounds

// Semantic
- favorite            // Red for favorites
- inactive            // Gray for disabled
- separator           // Divider lines

// Folder/Filter Colors
- filterAll, filterFavorite, filterRecent
- folderColors: [Color]  // Cycle through for custom folders
```

**Dark Mode Support:**
```swift
static var surface: Color {
    Color(.secondarySystemBackground)  // Auto-adapts
}

// Manual dark/light colors
static var surfaceLight: Color {
    Color(
        light: Color(red: 0.96, green: 0.97, blue: 0.98),
        dark: Color(red: 0.15, green: 0.15, blue: 0.18)
    )
}
```

### Typography (`Fonts`)
Custom font definitions and text styles.

### Spacing (`Spacing`)
Consistent spacing values used throughout UI.

### Images (`Images`)
Centralized image asset references.

### Strings (`AppStrings`)
Localization-ready string constants.

---

## Technical Implementation Details

### 1. Memory Management

**PDF Document Lifecycle:**
```swift
// PDFViewerViewModel
init(pdfFile: PDFModelData, repository: PDFRepositoryProtocol) {
    // Start security-scoped access
    if let url = pdfFile.resolveSecureURL() {
        currentPDF = url
    }
}

deinit {
    cancellables.removeAll()
}

func unloadPdfData() {
    saveLastOpenedPageNumberInDb(isFinal: true)
    currentPDF?.stopAccessingSecurityScopedResource()
    cancellables.removeAll()
}
```

**Canvas View Recycling:**
- Only creates canvases for currently visible pages
- Removes canvases when pages scroll out of view
- Saves annotation data to cache before removal

### 2. Performance Optimizations

**Thumbnail Generation:**
- Generated on first import (background thread)
- Cached in memory during session
- Stored as image data could be added for persistence

**Debounced Operations:**
```swift
// Page change tracking (5 second debounce)
pageChangeSubject
    .debounce(for: .seconds(5), scheduler: RunLoop.main)
    .sink { [weak self] page in
        self?.saveLastOpenedPageNumberInDb()
    }
    .store(in: &cancellables)
```

**Lazy Loading:**
- PDFs loaded on-demand (not all at once)
- Metadata extracted only when needed
- Annotations loaded per-page

### 3. State Management

**Combine Publishers:**
```swift
// Repository returns publishers
func retrieve() -> AnyPublisher<[PDFModelData], Error> {
    store.retrieve()
        .tryMap { pdfCoreDataList in
            pdfCoreDataList.compactMap { $0.toPDfModelData() }
        }
        .eraseToAnyPublisher()
}

// ViewModel subscribes
repository.retrieve()
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] pdfs in
        self?.allPdfModels = pdfs
    })
    .store(in: &cancellables)
```

### 4. Error Handling

**Repository Layer:**
```swift
func getSingleData(pdfKey: String) -> AnyPublisher<PDFModelData, Error> {
    store.filter(parameters: ["key": pdfKey])
        .tryMap { entities in
            guard let entity = entities.first else {
                throw NSError(
                    domain: "Repository", 
                    code: 404, 
                    userInfo: [NSLocalizedDescriptionKey: "PDF not found"]
                )
            }
            return entity.toCoreDataModel().toPDfModelData()
        }
        .eraseToAnyPublisher()
}
```

### 5. User Preferences

**UserDefaults Storage:**
```swift
// UserDefaultsHelper.swift
class UserDefaultsHelper {
    static let shared = UserDefaultsHelper()
    
    @UserDefault(key: "savedReadingMode")
    var savedReadingMode: String?
    
    @UserDefault(key: "savedBrightness")
    var savedBrightness: CGFloat = 100
}

// Property wrapper for convenience
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
```

### 6. Annotation Persistence Flow

**Complete Flow:**
```
1. User draws on canvas (PencilKit)
   ↓
2. PKCanvasView captures drawing
   ↓
3. On page change/app background:
   - Serialize PKDrawing to Data
   - Store in memory cache: annotationManager.updateCache()
   ↓
4. On document close/periodic save:
   - Get all cached drawings
   - Serialize to JSON: { "page_0": "base64data", "page_1": "..." }
   - Save to Core Data via Repository
   ↓
5. On document open:
   - Load annotation data from Core Data
   - Deserialize JSON
   - Populate memory cache
   ↓
6. As pages become visible:
   - Check cache for page's drawing
   - If exists, load into PKCanvasView
```

### 7. Import Duplicate Detection

**Key Generation:**
```swift
func generatePDFKey(from bookmarkData: BookmarkDataClass) -> String {
    // Use file metadata to create unique key
    let urlString = bookmarkData.url.absoluteString
    let fileName = bookmarkData.url.lastPathComponent
    return "\(fileName)_\(urlString.hashValue)"
}

// Check before import
let existingKeys = Set(allPdfModels.map { $0.key })
if existingKeys.contains(generatedKey) {
    // Skip duplicate
    continue
}
```

### 8. UI Responsiveness During Import

**Background Processing:**
```swift
func importPDFsAndForget(urls: [BookmarkDataClass]) {
    let existingKeys = Set(allPdfModels.map { $0.key })
    let vm = PDFImportViewModel(
        bookmarkDatas: urls, 
        repository: repository, 
        existingKeys: existingKeys
    )
    
    // Process on background thread
    DispatchQueue.global(qos: .userInitiated).async {
        vm.processPDFs()
    }
    
    // Show progress UI
    self.importViewModel = vm
    self.isShowingImportProgress = true
}
```

---

## Summary

### Architecture Strengths
✅ **Clean Separation of Concerns**: MVVM + Repository pattern
✅ **Testability**: ViewModels and Repository are easily testable
✅ **Reactive**: Combine for data flow and state management
✅ **Scalability**: Feature-based organization allows independent development
✅ **Modern iOS**: SwiftUI with strategic UIKit integration

### Key Features
🎨 **Rich Annotations**: PencilKit integration with persistence
📚 **Flexible Organization**: Folders, favorites, recent views
🔍 **Search**: Full-text search across title and author
💾 **Non-Destructive**: Uses bookmarks, doesn't copy files
🌓 **Dark Mode**: Full support with semantic colors
📖 **Reading Modes**: Multiple display modes and brightness control
♻️ **Memory Efficient**: Dynamic canvas creation and cleanup
🚀 **Performance**: Background processing, debounced saves, lazy loading

### Technologies Used
- **SwiftUI**: Primary UI framework
- **UIKit**: PDFKit for rendering, PencilKit for annotations
- **Combine**: Reactive programming and state management
- **Core Data**: Local persistence
- **Security-Scoped Bookmarks**: File access without copying
- **Property Wrappers**: UserDefaults, Published, Binding
- **MVVM**: Architecture pattern
- **Repository Pattern**: Data access abstraction

---

*Documentation generated on February 9, 2026*
*Project: PDFViewer for iOS*
*Version: 1.0*
