// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
mod commands;
mod input;
mod record;
mod state;

use commands::*;
use input::InputData;
use state::AppState;
use std::sync::Mutex;
use tauri::{Builder, Manager};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    Builder::default()
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_store::Builder::default().build())
        .plugin(tauri_plugin_prevent_default::debug())
        .setup(|app| {
            let handle = app.handle();
            let state = AppState::load_from_store(handle)?;
            app.manage(Mutex::new(state));
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            create_record,
            read_clipboard,
            calc_loading_volumn,
            update_loading_volumn,
            get_record,
            get_history,
            clear_history,
            delete_history
        ])
        .on_window_event(|window, event| match event {
            tauri::WindowEvent::CloseRequested { api, .. } => {
                api.prevent_close();
                let handle = window.app_handle();
                let state = handle.state::<Mutex<AppState>>();
                let state_guard = state.lock().unwrap();
                if let Err(e) = state_guard.save_to_store(handle) {
                    eprintln!("Failed to save state before closing: {}", e);
                }
                handle.exit(0);
            }
            _ => {}
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
