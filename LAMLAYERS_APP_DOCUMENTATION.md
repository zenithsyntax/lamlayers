# LamLayers - Complete App Documentation

## Overview

**LamLayers** is a Flutter-based digital design and scrapbook creation app that allows users to create posters, designs, and interactive flip books (called "Lambooks"). The app features:

- **Poster Maker**: Create custom designs with text, images, shapes, and drawings
- **Lambook Creator**: Build interactive flip books with multiple pages
- **Google Drive Integration**: Export and share Lambooks via Google Drive
- **Local Storage**: Projects stored locally using Hive database
- **Deep Linking**: Open .lamlayers and .lambook files directly
- **Ad-Supported**: Google Mobile Ads integration

---

## App Architecture

### Technology Stack

- **Framework**: Flutter (Dart SDK ^3.9.2)
- **Database**: Hive (NoSQL local database)
- **Authentication**: Google Sign-In (for Drive integration)
- **Cloud Storage**: Google Drive API (for file sharing)
- **Ads**: Google Mobile Ads SDK
- **Image Processing**: image package, pro_image_editor, image_cropper
- **Export**: archive package for ZIP file creation
- **Sharing**: share_plus for native sharing

### Main Dependencies

```yaml
- hive: ^2.2.3
- google_sign_in: ^6.2.1
- googleapis: ^13.2.0
- google_mobile_ads: ^5.1.0
- image: ^4.5.4
- archive: ^4.0.7
- pro_image_editor: ^11.10.0
- permission_handler: ^12.0.0
- flutter_screenutil: ^5.9.3
```

---

## App Structure

### 1. **Home Page** (`lib/screens/home_page.dart`)

The main entry point with three tabs:

#### Tab 1: Design
- **Quick Actions**:
  - Create New: Start a fresh poster project
  - Load Project: Import .lamlayers files
- **Recent Projects**: Displays saved poster projects
- Shows motivational design quotes

#### Tab 2: Lambook
- **Quick Actions**:
  - Create New: Start a new lambook (scrapbook)
  - Load Lambook: Import .lambook files
- **Recent Lambooks**: Displays saved scrapbooks

#### Tab 3: Settings
- App settings and preferences

### 2. **Key Features & Screens**

#### A. Canvas Preset Screen (`canvas_preset_screen.dart`)
- Choose canvas dimensions before starting a project
- Pre-defined templates:
  - Square (1080x1080)
  - Portrait (1080x1920)
  - Landscape (1920x1080)
  - Custom dimensions
- Option to add background image

#### B. Poster Maker Screen (`poster_maker_screen.dart`)
Main design editor with:
- **Canvas Items**: Text, Images, Shapes, Stickers, Drawings
- **Editing Tools**:
  - Transform controls (scale, rotate, position)
  - Layer management
  - Undo/Redo system
  - Nudge controls
  - Alignment guides
- **Drawing Tools**:
  - Brush with varying opacity and width
  - Eraser
  - Color picker
- **Text Features**:
  - Custom fonts (Google Fonts)
  - Size, color, style
  - Text along paths
- **Export Options**: PNG/JPEG with quality settings

#### C. Scrapbook Manager Screen (`scrapbook_manager_screen.dart`)
Manages Lambook pages:
- Grid/List view of pages
- Add blank pages or from templates
- Reorder pages (drag & drop)
- Duplicate pages
- Delete pages
- Edit individual pages
- Export as .lambook file
- Share to Google Drive

#### D. Scrapbook Flip Book View (`scrapbook_flip_book_view.dart`)
Interactive reader for Lambooks:
- Page turn animations
- Customizable covers:
  - Left/Right cover colors or images
  - Background scaffold color or image
- Export as individual images
- Share to Google Drive with web viewer link
- Settings for customization

---

## Google Drive Integration

### Purpose
Google Drive is used to **share Lambooks** with a web viewer, allowing users to view their flip books in a browser.

### How It Works

#### 1. **Google Drive Share Service** (`lib/services/google_drive_share_service.dart`)

This service handles the complete flow of uploading to Google Drive and making files publicly accessible.

##### Key Methods:

```dart
// Gets authenticated Drive API instance
Future<drive.DriveApi> _getDriveApi() async {
  // Signs in with Google (silently or interactively)
  // Creates authenticated HTTP client
}

// Uploads file and makes it public
Future<String> uploadAndMakePublic({
  required String fileName,
  required Uint8List bytes,
  String mimeType = 'application/octet-stream',
}) async {
  // 1. Create file metadata
  // 2. Upload file with media stream
  // 3. Get fileId from created file
  // 4. Set public read permission (anyone with link)
  // 5. Return fileId for URL generation
}
```

#### 2. **Integration Flow in Scrapbook Flip Book View**

When a user clicks "Share via Google Drive" in the lambook reader:

```dart
// Step 1: User is prompted to sign in with Google
GoogleSignInAccount? account = await _ensureSignedInToGoogle();

// Step 2: Export lambook to temporary file
final String? path = await ExportManager.exportScrapbookLambook(
  scrapbook: scrapbook,
  pages: pages,
  scaffoldBgColor: _scaffoldBgColor,
  leftCoverColor: _leftCoverColor,
  rightCoverColor: _rightCoverColor,
);

// Step 3: Read file as bytes
final fileBytes = await File(path).readAsBytes();

// Step 4: Upload to Drive and get fileId
final driveService = GoogleDriveShareService();
final fileId = await driveService.uploadAndMakePublic(
  fileName: '${scrapbook.name}.lambook',
  bytes: fileBytes,
  mimeType: 'application/octet-stream',
);

// Step 5: Generate web viewer URL
final webUrl = 'https://lamlayers.com/viewer?fileId=$fileId';

// Step 6: Share the link
Share.share(text: 'Check out my lambook!\n$webUrl');
```

#### 3. **Authentication Scopes**

The app requests these Google Drive scopes:
```dart
[
  drive.DriveApi.driveFileScope,  // Create files you open/create
  drive.DriveApi.driveScope,      // Broader access for permissions
]
```

### Security & Permissions

- **Sign-In**: Uses `google_sign_in` package for secure authentication
- **Public Links**: Files are set to "anyone with the link can view"
- **No Edit Access**: Recipients can only view, not edit
- **File Type**: `.lambook` files are binary archives

---

## Data Models

### 1. **Scrapbook** (Lambook Container)
```dart
class Scrapbook {
  String id;                      // Unique identifier
  String name;                    // Lambook name
  DateTime createdAt;
  DateTime lastModified;
  List<String> pageProjectIds;    // Ordered list of page IDs
  double pageWidth;               // Standard page width
  double pageHeight;              // Standard page height
}
```

### 2. **PosterProject** (Individual Page/Design)
```dart
class PosterProject {
  String id;
  String name;
  DateTime createdAt;
  DateTime lastModified;
  List<HiveCanvasItem> canvasItems;  // Elements on canvas
  ProjectSettings settings;
  String? thumbnailPath;             // Preview image
  double canvasWidth;
  double canvasHeight;
  HiveColor canvasBackgroundColor;
  String? backgroundImagePath;
}
```

### 3. **HiveCanvasItem** (Elements on Canvas)
```dart
class HiveCanvasItem {
  String id;
  HiveCanvasItemType type;        // text, image, shape, sticker
  Offset position;
  double scale;
  double rotation;
  double opacity;
  int layerIndex;
  bool isVisible;
  bool isLocked;
  Map<String, dynamic> properties; // Type-specific data
  String? groupId;                 // For grouping
  String? name;                    // Custom name
}
```

---

## File Formats

### 1. **.lamlayers** (Project File)
A ZIP archive containing:
- `project.json`: Project metadata and canvas items
- `images/`: Referenced image files

**Structure:**
```
project.lamlayers
├── project.json
├── images/
│   ├── image_001.png
│   └── image_002.jpg
```

**project.json contains:**
- Project info (name, dimensions, settings)
- Background color/image
- Array of canvas items with properties
- Images embedded as base64

### 2. **.lambook** (Scrapbook File)
A ZIP archive containing:
- `scrapbook.json`: Book metadata and customization
- `pages/`: Individual page JSON files

**Structure:**
```
my_lambook.lambook
├── scrapbook.json
└── pages/
    ├── page_000.json
    ├── page_001.json
    └── page_002.json
```

**scrapbook.json contains:**
```json
{
  "id": "s_123456",
  "name": "My Lambook",
  "pageWidth": 1600,
  "pageHeight": 1200,
  "scaffoldBackground": {
    "color": {"value": 4294967295},
    "imageBase64": "..."
  },
  "leftCover": {
    "color": {"value": 4292344284},
    "imageBase64": "..."
  },
  "rightCover": {
    "color": {"value": 4294967295},
    "imageBase64": "..."
  }
}
```

---

## Export & Loading Workflow

### Export Process (ExportManager)

#### For Individual Projects:
```dart
1. Gather all canvas items
2. Convert images to base64 or copy to archive
3. Serialize project to JSON
4. Create ZIP archive with project.json + images/
5. Save to file system
6. Return file path for sharing
```

#### For Lambooks:
```dart
1. Create ZIP archive
2. Serialize scrapbook.json with metadata
3. For each page:
   - Serialize to JSON with embedded images
   - Add as pages/page_XXX.json
4. Write ZIP to file
5. Return file path
```

### Loading Process

#### Loading .lambook Files:
```dart
1. Read ZIP archive
2. Extract scrapbook.json
3. Parse book metadata
4. Extract all page_*.json files in order
5. Decode base64 images to temp directory
6. Return LambookData object with:
   - LambookMeta (customization settings)
   - List<PosterProject> (pages)
```

#### Deep Linking:
- Android Intent filters for .lamlayers and .lambook files
- MethodChannel handles file paths
- Loads and opens files automatically

---

## Deep Linking Implementation

### Native Android Side
Handles file associations and passes paths to Flutter via MethodChannel.

### Flutter Side (DeepLinkHost in main.dart)

```dart
// Receives file paths from native
_handleMethodCall(MethodCall call) async {
  if (call.method == 'openedFile') {
    String path = call.arguments['path'];
    
    // Detect file type
    if (path.endsWith('.lamlayers')) {
      // Load as project
      await _openLamlayersProject(path);
    } else if (path.endsWith('.lambook')) {
      // Load as lambook
      final data = await ExportManager.loadLambook(path);
      // Navigate to flip book viewer
      Navigator.push(...);
    }
  }
}
```

---

## Google Drive Sharing Flow (Detailed)

### Complete User Journey:

1. **User Opens Lambook**
   - Views pages in flip book reader
   - Clicks "Share" button

2. **Sign-In Prompt**
   ```dart
   GoogleSignInAccount? account = await _ensureSignedInToGoogle();
   ```
   - If not signed in, shows Google Sign-In dialog
   - Requests scopes: Drive File API + Drive API

3. **Export Lambook**
   ```dart
   await ExportManager.exportScrapbookLambook(
     scrapbook: scrapbook,
     pages: pages,
     // ... customization settings
   );
   ```
   - Creates ZIP file
   - Embeds images as base64
   - Returns file path

4. **Read File Bytes**
   ```dart
   final fileBytes = await File(path).readAsBytes();
   ```

5. **Initialize Drive Service**
   ```dart
   final driveService = GoogleDriveShareService();
   ```
   - Creates `GoogleSignIn` instance with Drive scopes
   - Gets authenticated account (silently or interactively)

6. **Get Drive API Client**
   ```dart
   final driveApi = await _getDriveApi();
   ```
   - Extracts auth headers from signed-in account
   - Wraps HTTP client with authentication headers
   - Returns `drive.DriveApi` instance

7. **Upload File**
   ```dart
   final drive.File fileMetadata = drive.File()
     ..name = 'MyLambook.lambook'
     ..mimeType = 'application/octet-stream';
   
   final media = drive.Media(
     Stream.fromIterable([fileBytes]),
     fileBytes.length,
   );
   
   final created = await driveApi.files.create(
     fileMetadata,
     uploadMedia: media,
   );
   ```
   - Creates file metadata
   - Uploads file with media stream
   - Returns file object with ID

8. **Make Public**
   ```dart
   await driveApi.permissions.create(
     drive.Permission()
       ..type = 'anyone'
       Turtle role = 'reader',
     fileId,
   );
   ```
   - Sets "anyone with the link" permission
   - Allows web viewer access without login

9. **Generate Web URL**
   ```dart
   final webUrl = 'https://lamlayers.com/viewer?fileId=$fileId';
   ```
   - Uses fileId in web viewer URL
   - Web app can download and render the lambook

10. **Share Link**
    ```dart
    await Share.share(text: 'Check out my lambook!\n$webUrl');
    ```
    - Opens native share sheet
    - User can share via any app

### Technical Details:

#### Auth Client Implementation:
```dart
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = IOClient(HttpClient());
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);  // Add OAuth2 headers
    return _inner.send(request);
  }
}
```

#### Error Handling:
- File upload failures → Fallback to local share
- Permission errors → User prompted to grant access
- Network errors → Retry or show error message

---

## Local Storage (Hive Database)

### Structure:

```
Hive Boxes:
- 'posterProjects'  → Box<PosterProject>
- 'scrapbooks'      → Box<Scrapbook>
- 'userPreferences' → Box<UserPreferences>
```

### Location:
Android: `/data/user/0/com.lamlayers.app/databases/`
iOS: App Documents Directory

### Features:
- Type-safe storage with code generation
- Reactive updates with `ValueListenableBuilder`
- Persistent across app restarts
- Fast local access

---

## Advertising Integration

### Ad Units:
- **Interstitial Ads**: Shown when adding pages from templates
- **Banner Ads**: (Implementation not shown in provided code)

### Ad Flow:
```dart
1. Load ad in background
2. On certain actions (e.g., template selection):
   - Show interstitial ad
   - Proceed after ad is dismissed or fails
3. Reload ad for next use
```

---

## Permissions Required

### Android:
- `READ_MEDIA_IMAGES` (Android 13+)
- `WRITE_EXTERNAL_STORAGE` (Android 10-12)
- `MANAGE_EXTERNAL_STORAGE` (OEM-specific)

### iOS:
- `PHPhotoLibraryAddOnly` (Add photos permission)

---

## Key Utilities

### 1. **ExportManager** (`utils/export_manager.dart`)
- Export projects as .lamlayers files
- Export scrapbooks as .lambook files
- Load and parse saved files
- Image format conversion
- Permission handling
- Thumbnail generation

### 2. **Canvas Renderer** (`widgets/canvas_renderer.dart`)
- Renders canvas items on screen
- Handles transformations
- Manages layer rendering order
- Provides preview for export

---

## Design Patterns

1. **State Management**: setState + ValueListenableBuilder
2. **Navigation**: MaterialPageRoute for screens
3. **Data Persistence**: Hive for local, Google Drive for sharing
4. **Separation of Concerns**:
   - Screens: UI logic
   - Utils: Business logic
   - Services: External integrations
   - Models: Data structures

---

## User Flows

### Creating a Poster:
```
Home → Create New → Canvas Preset → Poster Maker → Edit → Export
```

### Creating a Lambook:
```
Home → Create Lambook → Name Dialog → Scrapbook Manager → 
Add Pages → Edit Pages → Export as .lambook
```

### Sharing via Google Drive:
```
Lambook Viewer → Share → Google Sign-In → Export → Upload → 
Make Public → Generate URL → Share Link
```

---

## Summary

**LamLayers** is a comprehensive design and scrapbook app that combines:

1. **Local Design Tools**: Full-featured poster/presentation editor
2. **Interactive Books**: Flip book creation and reading
3. **Cloud Sharing**: Google Drive integration for web viewing
4. **File Portability**: Export/import via .lamlayers and .lambook formats
5. **User-Friendly**: Intuitive UI with animations and templates

The Google Drive integration specifically enables users to share their interactive lambooks with anyone via a web link, making it accessible without requiring the app.

