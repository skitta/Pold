# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pold is a Tauri-based desktop application that appears to be a data analysis tool for processing ImageJ-style clipboard data. The app calculates statistics and volume modifications based on input data, maintaining a history of records.

## Architecture

**Frontend (Vue 3 + TypeScript):**
- Vue 3 with Composition API and `<script setup>` syntax
- Vue Router for navigation with custom slide animations
- Arco Design Vue components for UI
- Vite for build tooling and development server

**Backend (Rust + Tauri):**
- Tauri v2 for desktop app framework
- Rust backend handles data processing and state management
- Clipboard integration via `tauri-plugin-clipboard-manager`
- Persistent storage using `tauri-plugin-store`
- Main modules: `commands.rs`, `record.rs`, `input.rs`, `state.rs`

**Key Backend Components:**
- `AppState`: Manages application state and persistence
- `Record`: Represents a data record with inputs, statistics, and timestamps
- `InputData`: Parses and processes ImageJ-style data from clipboard
- Commands: Bridge between frontend and backend via Tauri's invoke system

## Development Commands

**Frontend Development:**
```bash
npm run dev          # Start Vite development server
npm run build        # Build Vue app (runs TypeScript check first)
npm run preview      # Preview production build
```

**Tauri Development:**
```bash
npm run tauri dev    # Start Tauri development mode
npm run tauri build  # Build Tauri app for production
```

**Build Process:**
- Frontend: `vue-tsc --noEmit && vite build`
- Tauri automatically handles Rust compilation
- No test commands are configured in package.json

## State Management

The application uses a centralized state management pattern:
- `AppState` in Rust manages all application data
- State is persisted using Tauri's store plugin
- Frontend communicates with backend via Tauri commands
- State updates are pushed to frontend via Tauri events

## Key Features

1. **Clipboard Data Processing**: Parses ImageJ-style data from clipboard
2. **Statistics Calculation**: Computes min, max, and average values
3. **Volume Modification**: Calculates modified volumes based on target values
4. **History Management**: Maintains chronological records with timestamps
5. **Persistent Storage**: Saves state across app restarts

## Frontend Structure

- `App.vue`: Main app component with router transitions
- `views/`: Page components (Home, About)
- `components/`: Reusable UI components (TableView)
- `router/`: Vue Router configuration
- `utils/`: Utility functions (Tauri event handling)

## Backend Structure

- `lib.rs`: Main Tauri application setup and plugin configuration
- `commands.rs`: Tauri command handlers for frontend communication
- `state.rs`: Application state management and persistence
- `record.rs`: Data record structure and statistics calculation
- `input.rs`: Data input parsing and processing

## Development Notes

- Uses Tauri v2 with modern plugin system
- TypeScript strict mode enabled
- Rust profile optimized for release builds
- Desktop app configured for 800x600 window size
- CSP disabled for development flexibility