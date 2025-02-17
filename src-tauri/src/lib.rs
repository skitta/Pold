// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
use tauri::AppHandle;
use tauri_plugin_clipboard_manager::ClipboardExt;

#[derive(serde::Serialize)]
struct ClipboardData<'a> {
    key: &'a str,
    name: &'a str,
    volumn: u8,
    value: f64,
}

#[tauri::command]
fn read_clipboard(app: AppHandle) -> Result<String, String> {
    let content = app.clipboard().read_text().map_err(|e| e.to_string())?;
    let parse_data: Vec<ClipboardData> = content
        .lines()
        .filter_map(|line| {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() == 2 {
                let key = parts[0];
                let value = parts[1].parse::<f64>().ok()?;
                Some(ClipboardData {
                    key,
                    name: key,
                    volumn: 0,
                    value,
                })
            } else {
                None
            }
        })
        .collect();
    // todo: 处理读取错误
    if parse_data.is_empty() {
        return Err("No valid data found in clipboard".to_string());
    }
    serde_json::to_string(&parse_data).map_err(|e| e.to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_clipboard_manager::init())
        .invoke_handler(tauri::generate_handler![read_clipboard])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
