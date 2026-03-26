# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pold is a desktop application for scientific data analysis that processes ImageJ-style clipboard data. The app calculates statistics and volume modifications based on input data, maintaining a history of records. The repository contains two implementations:

1. **SwiftUI macOS app** (`Pold/`) - Current primary implementation using SwiftUI
2. **Tauri+Vue app** (`/`) - Original desktop application using Tauri v2 with Vue 3 frontend

## Architecture

### SwiftUI macOS App (`Pold/`)

**Framework & Tools:**
- SwiftUI with `@Observable` macro for state management
- Native macOS `Table` component for data display
- `NavigationSplitView` for sidebar-detail layout
- Xcode project: `Pold/Pold.xcodeproj`
- Persistence: JSON file at `~/Library/Application Support/Pold/history.json`

**Key SwiftUI Components:**
- `PoldApp`: Main app entry point with `WindowGroup`
- `ContentView`: NavigationSplitView with sidebar (history list) and detail (table editor)
- `AppState`: `@Observable` class managing all application state
- `TableEditorView`: Editable table with input rows and target slider
- `HistoryRow`: Individual history record row with inline rename
- `ClipboardService`: Reads and parses ImageJ-style data from macOS clipboard

**Data Models:**
- `Record`: Contains id, name, inputs array, min/max/target values
- `InputData`: Individual data point with key, name, volumn, value, modifiedVolumn

### Tauri+Vue App (`/`)

**Frontend (Vue 3 + TypeScript):**
- Vue 3 with Composition API and `<script setup>` syntax
- Vue Router 4 for navigation with custom slide animations
- Arco Design Vue components for UI (via `@arco-plugins/vite-vue`)
- Vite 6 for build tooling with strict port 1420 for Tauri compatibility
- TypeScript strict mode enabled
- Path alias `@` maps to `src/`

**Backend (Rust + Tauri v2):**
- Tauri v2 with modern plugin system
- Main modules: `commands.rs`, `record.rs`, `input.rs`, `state.rs`, `lib.rs`
- Plugins: `clipboard-manager`, `store` (persistence), `prevent-default`
- Window: 800×600 pixels
- Development: Port 1420 with strict port setting, CSP disabled for dev
- Build: Rust optimized for release (LTO, codegen-units=1, strip=true)

## Development Commands

### SwiftUI App Development
```bash
# Open in Xcode
open Pold/Pold.xcodeproj

# Or use xcodebuild from command line
xcodebuild -project Pold/Pold.xcodeproj -scheme Pold -configuration Debug build
xcodebuild -project Pold/Pold.xcodeproj -scheme Pold -configuration Release build
```

### Tauri App Development
```bash
# Frontend development
npm run dev          # Start Vite dev server on port 1420
npm run build        # Build Vue app (vue-tsc --noEmit && vite build)
npm run preview      # Preview production build

# Tauri development
npm run tauri dev    # Start Tauri in development mode
npm run tauri build  # Build Tauri app for production
```

### Build Process
1. **SwiftUI**: Standard Xcode build (Debug/Release)
2. **Vue Frontend**: `vue-tsc --noEmit && vite build` → outputs to `dist/`
3. **Tauri**: Bundles frontend from `../dist/`, compiles Rust with release optimizations

## Key Features

1. **Clipboard Data Processing**: Parses ImageJ-style data (tab/space separated key-value pairs)
2. **Statistics Calculation**: Computes min, max, and average values from inputs
3. **Volume Modification**: Calculates modified volumes based on target values
4. **History Management**: Maintains chronological records with custom names
5. **Persistent Storage**: Saves state across app restarts (JSON file for SwiftUI, store plugin for Tauri)

## Project Structure

### SwiftUI App (`Pold/`)
```
Pold/
├── Pold.xcodeproj/          # Xcode project
├── Assets.xcassets/         # App icons and colors
└── Pold/                    # Source files
    ├── PoldApp.swift        # App entry point
    ├── ContentView.swift   # Main navigation view
    ├── AppState.swift      # Observable state management
    ├── Record.swift        # Data record model
    ├── InputData.swift     # Input data model with parsing
    ├── TableEditorView.swift # Editable data table
    ├── HistoryRow.swift    # History list row
    ├── AboutView.swift     # About/help view
    ├── ClipboardService.swift # Clipboard reading
    └── UIAnimations.swift  # Animation definitions
```

### Tauri App (`/`)
```
src/
├── App.vue              # Main app with router slide animations
├── main.ts              # Vue entry point
├── views/               # Page components (Home.vue, About.vue)
├── components/          # Reusable UI (TableView.vue)
├── router/              # Vue Router config (2 routes)
└── utils/               # Utilities (useTauriEvent.ts)

src-tauri/
├── lib.rs               # Tauri app setup and plugin config
├── commands.rs          # Command handlers for frontend
├── state.rs             # AppState management and persistence
├── record.rs            # Record structure and statistics
├── input.rs             # Data input parsing
└── main.rs              # Application entry point
```

## Data Flow (SwiftUI App)

1. **Clipboard Import**: `ClipboardService.readClipboard()` → parses ImageJ-style text → `Result<[InputData], Error>`
2. **State Management**: `AppState` (@Observable) holds `recordHistory: [Record]` and `currentIndex`
3. **Record Updates**: `Record.setInputs()` recalculates statistics, `modifiedInputVolumn()` computes target volumes
4. **Persistence**: Debounced save to `~/Library/Application Support/Pold/history.json` (250ms delay)
5. **UI Binding**: SwiftUI views observe `AppState` directly via `@State` property wrapper

## Development Notes

### SwiftUI Specifics
- Uses `@Observable` macro (iOS 17+/macOS 14+)
- `NavigationSplitView` for three-column layout (sidebar, detail, optional column)
- Native `Table` API for tabular data editing
- `onChange` modifiers track record/slider changes
- Preview providers for individual views

### Tauri Configuration
- **Vite**: Port 1420, strict port, HMR configured for Tauri, ignores `src-tauri/` in watch
- **Tauri**: Product name "Pold", identifier `com.skitta.pold`, version 0.2.2
- **Rust**: Release profile optimized for size (opt-level="s", LTO, strip=true)
- **TypeScript**: Strict mode, path alias `@` for `src/`

### Communication Patterns (Tauri)
- Frontend → Backend: Tauri commands via `invoke()`
- Backend → Frontend: Tauri events via `emit()`
- State updates: Backend emits `"history"` and `"record"` events
- Frontend listens: `useTauriEvent("history", callback)`