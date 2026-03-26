# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

Pold is a desktop application for scientific data analysis that processes ImageJ-style clipboard data. The app calculates statistics and volume modifications based on input data, maintaining a history of records. The repository contains two implementations:

1. **Main Tauri+Vue app** - Primary desktop application using Tauri v2 with Vue 3 frontend
2. **Experimental GPUI app** (`pold-gpui/`) - Alternative implementation using GPUI framework (Rust GUI)

## Architecture

### Main Tauri+Vue App

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

**Key Backend Components:**
- `AppState`: Centralized state management with persistence to `history.json`
- `Record`: Data record with inputs, statistics (min/max/average), timestamps
- `InputData`: Parses ImageJ-style clipboard data (tab/space separated values)
- Commands: Bridge between frontend and backend via Tauri's invoke system

### Experimental GPUI App (`pold-gpui/`)
- Pure Rust GUI application using GPUI framework
- Similar modules: `state.rs`, `record.rs`, `input.rs`, `clipboard.rs`
- Uses `gpui` and `gpui-component` crates instead of Tauri
- Clipboard integration via `clipboard` crate
- Asynchronous I/O with Tokio
- Experimental alternative to Tauri-based app

## Development Commands

### Main App Development
```bash
# Frontend development
npm run dev          # Start Vite dev server on port 1420
npm run build        # Build Vue app (vue-tsc --noEmit && vite build)
npm run preview      # Preview production build

# Tauri development
npm run tauri dev    # Start Tauri in development mode
npm run tauri build  # Build Tauri app for production
```

### GPUI App Development
```bash
cd pold-gpui
cargo run           # Build and run GPUI app
cargo build         # Build GPUI app
```

### Build Process
1. **Frontend**: `vue-tsc --noEmit && vite build` → outputs to `dist/`
2. **Tauri**: Bundles frontend from `../dist/`, compiles Rust with release optimizations
3. **GPUI**: Standard Rust build with `cargo build/run`

## State Management & Data Flow

### Main App Architecture
- Centralized `AppState` in Rust backend manages all application data
- State persisted using Tauri's store plugin (`history.json`)
- Frontend communicates via Tauri commands (e.g., `invoke("create_record")`)
- Backend emits events to frontend (e.g., `"history"`, `"record"`)
- Frontend listens via `useTauriEvent` hook in `utils/useTauriEvent.ts`

### Data Processing Pipeline
1. **Input**: ImageJ-style clipboard data (tab/space separated values)
2. **Parsing**: `InputData` parses values, calculates statistics
3. **Calculation**: Min, max, average values; volume modifications based on target
4. **Storage**: Records stored in chronological history with timestamps
5. **Persistence**: State saved to `history.json` via Tauri store plugin

## Key Features

1. **Clipboard Data Processing**: Parses ImageJ-style data from clipboard
2. **Statistics Calculation**: Computes min, max, and average values
3. **Volume Modification**: Calculates modified volumes based on target values
4. **History Management**: Maintains chronological records with timestamps
5. **Persistent Storage**: Saves state across app restarts
6. **Dual Implementation**: Tauri+Vue (main) and GPUI (experimental) versions

## Project Structure

### Main App (`/`)
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

### GPUI App (`pold-gpui/`)
```
src/
├── main.rs              # GPUI application entry point
├── state.rs             # State management
├── record.rs            # Record structure
├── input.rs             # Data parsing
└── clipboard.rs         # Clipboard integration
```

## Development Notes

### Configuration Details
- **Vite**: Port 1420, strict port, HMR configured for Tauri, ignores `src-tauri/` in watch
- **Tauri**: Product name "Pold", identifier `com.skitta.pold`, version 0.2.2
- **Rust**: Release profile optimized for size (opt-level="s", LTO, strip=true)
- **TypeScript**: Strict mode, path alias `@` for `src/`

### Communication Patterns
- Frontend → Backend: Tauri commands via `invoke()`
- Backend → Frontend: Tauri events via `emit()`
- State updates: Backend emits `"history"` and `"record"` events
- Frontend listens: `useTauriEvent("history", callback)`

### Experimental GPUI App
- Pure Rust alternative to Tauri-based app
- Uses GPUI framework for native Rust GUI
- Similar functionality but different architecture
- Considered experimental/alternative implementation