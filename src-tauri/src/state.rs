use crate::record::Record;
use serde_json::json;
use tauri::{AppHandle, Emitter};
use tauri_plugin_store::StoreExt;

#[derive(serde::Serialize)]
pub struct AppState {
    record_history: Vec<Record>,
    current_index: Option<usize>,
}

impl AppState {
    pub fn load_from_store(app: &AppHandle) -> Result<Self, Box<dyn std::error::Error>> {
        let store = app.store("history.json")?;
        let history_list: Vec<Record> = match store.get("records") {
            Some(list) => serde_json::from_value(list)?,
            _ => Vec::new(),
        };
        let index: Option<usize>;
        if history_list.len() == 0 {
            index = None;
        } else {
            index = Some(0);
        }

        Ok(Self {
            record_history: history_list,
            current_index: index,
        })
    }

    pub fn set_index(&mut self, index: usize) {
        self.current_index = Some(index);
    }

    pub fn add_record(&mut self, record: Record) {
        self.record_history.insert(0, record);
        self.current_index = Some(0);
    }

    pub fn get_mut_current_record(&mut self) -> Option<&mut Record> {
        let index = self.current_index?;
        self.record_history.get_mut(index)
    }

    pub fn send_current_record(&self, app: &AppHandle) {
        if let Some(index) = self.current_index {
            let record = self.record_history.get(index);
            app.emit("record", record).unwrap();
        }
    }

    pub fn send_history_list(&self, app: &AppHandle) {
        let history = self
            .record_history
            .iter()
            .map(|record| record.get_display_name())
            .collect::<Vec<String>>();
        app.emit("history", history).unwrap();
    }

    pub fn delete_history(&mut self, index: usize) -> bool {
        if index < self.record_history.len() {
            self.record_history.remove(index);
            if self.current_index.is_some() && self.current_index.unwrap() >= index {
                self.current_index = Some(self.current_index.unwrap().saturating_sub(1));
            }
            true
        } else {
            false
        }
    }

    pub fn rename_record(&mut self, index: usize, name: String) -> bool {
        if let Some(record) = self.record_history.get_mut(index) {
            record.set_name(name);
            true
        } else {
            false
        }
    }

    pub fn clear_history(&mut self, app: &AppHandle) {
        self.record_history.clear();
        self.current_index = None;

        app.emit("history", Vec::<String>::new()).unwrap();
    }

    pub fn save_to_store(&self, app: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
        let store = app.store("history.json")?;
        store.set("records", json!(self.record_history));
        Ok(())
    }
}
