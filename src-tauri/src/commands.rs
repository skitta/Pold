use crate::state::AppState;
use crate::{input::InputData, record::Record};
use std::sync::Mutex;
use tauri::{AppHandle, State};
use tauri_plugin_clipboard_manager::ClipboardExt;

#[tauri::command]
pub fn create_record(app: AppHandle, state: State<'_, Mutex<AppState>>) -> Result<(), String> {
    let mut state = state.lock().unwrap();

    let record = Record::default();
    state.add_record(record);
    state.send_current_record(&app);
    state.send_history_list(&app);

    Ok(())
}

#[tauri::command]
pub fn read_clipboard(app: AppHandle) -> Result<String, String> {
    let content = app.clipboard().read_text().map_err(|e| e.to_string())?;
    let parse_data: Vec<InputData> = content
        .lines()
        .filter_map(|line| InputData::parse_imagej_line(line))
        .collect();
    if parse_data.is_empty() {
        return Err("No valid data found in clipboard".to_string());
    }

    serde_json::to_string(&parse_data).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn calc_loading_volumn(
    app: AppHandle,
    state: State<'_, Mutex<AppState>>,
    input_str: String,
) -> Result<(), String> {
    let mut state = state.lock().unwrap();
    let inputs = serde_json::from_str::<Vec<InputData>>(&input_str).map_err(|e| e.to_string())?;

    if let Some(record) = state.get_mut_current_record() {
        record.set_inputs(inputs);
        record.modified_input_volumn();
        state.send_current_record(&app);
    }

    Ok(())
}

#[tauri::command]
pub fn update_loading_volumn(app: AppHandle, state: State<'_, Mutex<AppState>>, target_value: u64) {
    let mut state = state.lock().unwrap();

    if let Some(record) = state.get_mut_current_record() {
        record.set_target(target_value);
        record.modified_input_volumn();
        state.send_current_record(&app);
    }
}

#[tauri::command]
pub fn get_record(app: AppHandle, state: State<'_, Mutex<AppState>>, index: usize) {
    let mut state = state.lock().unwrap();
    state.set_index(index);
    state.send_current_record(&app);
}

#[tauri::command]
pub fn get_history(app: AppHandle, state: State<'_, Mutex<AppState>>) {
    let state = state.lock().unwrap();
    state.send_history_list(&app);
}

#[tauri::command]
pub fn delete_history(
    app: AppHandle,
    state: State<'_, Mutex<AppState>>,
    index: usize,
) {
    let mut state = state.lock().unwrap();
    if state.delete_history(index) {
        state.send_history_list(&app);
        state.send_current_record(&app);
    } else {
        eprintln!("Failed to delete history at index {}", index);
    }
}

#[tauri::command]
pub fn clear_history(app: AppHandle, state: State<'_, Mutex<AppState>>) {
    let mut state = state.lock().unwrap();
    state.clear_history(&app);
}

#[tauri::command]
pub fn rename_history(
    app: AppHandle,
    state: State<'_, Mutex<AppState>>,
    index: usize,
    name: String,
) -> Result<(), String> {
    let mut state = state.lock().unwrap();
    if state.rename_record(index, name) {
        state.send_history_list(&app);
        Ok(())
    } else {
        Err(format!("Invalid index: {}", index))
    }
}

// #[tauri::command]
// async fn save_history(app: AppHandle, records: Vec<Record>) -> Result<String, String> {
//     let store = app.store("history.json").map_err(|e| e.to_string())?;
//     store.set("records".to_string(), json!(records));
//     store.save().map_err(|e| e.to_string())?;
//     Ok("ok".to_string())
// }
