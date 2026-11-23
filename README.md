# Application Tracker

A small macOS app to keep track of your job applications, and the HTML cover letters or CVs you send with them.

## Concept

- **One tab per year:** the sidebar lists every year you applied in. Each year shows a table of applications with company, job title, date, status and attached document.
- **One HTML document per application:** start from a blank template or import an existing HTML file. Edit it in a built-in code editor with syntax highlighting, linting and formatting.
- **Live preview:** see how the page will look while you type, open it in your browser, or export it as an A4 PDF.
- **Everything stays local:** all data is stored on your Mac. There is no account, cloud or tracking.

## Installation

1. Download the latest `application-tracker.zip` from [Releases](../../releases) and unzip it.
2. Move `application-tracker.app` to your Applications folder.
3. The app is not signed with an Apple Developer ID, so macOS blocks it on first launch. Open it once, then go to **System Settings → Privacy & Security** and click **Open Anyway**.

Requires macOS 27.2 or later.

## Usage

### Track applications

- Select a year in the sidebar.
- Click **+** (⌘N) to add an application with company, job title, date, status and notes.
- Click a column header to sort. Right-click a row to edit or delete it. Deleting can be undone with ⌘Z.

### Write the document

- Double-click an application to open its document window.
- Choose **New Document** to start from a template, or **Import HTML…** to bring in an existing file. You can also drop a file onto the window.
- Switch between **Editor**, **Editor and Preview** and **Preview** in the toolbar.
- **Format** (⇧⌥F) tidies the HTML with Prettier. The status bar shows lint errors and warnings.
- Changes are saved automatically.

### Images

Images are stored inside the app together with the document:

- Select them together with the HTML file when importing, or add them later via **Images → Add Images…**.
- Reference them by file name in your HTML, e.g. `<img src="photo.jpg">`. **Copy `<img>` Tag** in the Images menu does this for you.

### Share it

- **Open in Browser** shows the page in your default browser.
- **Export PDF** (⇧⌘E) saves the document as an A4 PDF.

## Building from source

Requires Xcode and [Node.js](https://nodejs.org) (e.g. `brew install node`). Open `application-tracker.xcodeproj` and run. The editor in `editor-web/` (CodeMirror, Prettier, HTMLHint) is built automatically by a build phase.
