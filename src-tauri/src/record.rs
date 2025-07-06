use crate::InputData;
use chrono::{TimeZone, Local};

#[derive(serde::Serialize, serde::Deserialize)]
pub struct Record {
    id: i64,
    inputs: Vec<InputData>,
    min_value: Option<u64>,
    max_value: Option<u64>,
    target_value: Option<u64>,
}

impl Default for Record {
    fn default() -> Self {
        Self {
            id: Local::now().timestamp_millis(),
            inputs: Vec::new(),
            min_value: None,
            max_value: None,
            target_value: None,
        }
    }
}

impl Record {
    pub fn set_inputs(&mut self, inputs: Vec<InputData>) {
        let (min, max, avg) = statistics(&inputs);
        self.min_value = Some(min);
        self.max_value = Some(max);
        self.target_value = Some(avg);
        self.inputs = inputs;
    }

    pub fn set_target(&mut self, target: u64) {
        self.target_value = Some(target);
    }

    pub fn modified_input_volumn(&mut self) {
        if let Some(target) = self.target_value {
            self.inputs.iter_mut().for_each(|input| {
                input.calc_modified_volumn(target);
            });
        }
    }

    pub fn get_display_name(&self) -> String {
        let dt = Local.timestamp_millis_opt(self.id).unwrap();
        dt.format("%Y-%m-%d %H:%M:%S").to_string()
    }
}

fn statistics(inputs: &Vec<InputData>) -> (u64, u64, u64) {
    let (min, max, sum) = inputs.iter().fold(
        (f64::INFINITY, f64::NEG_INFINITY, 0.0),
        |(min_acc, max_acc, sum_acc), x| {
            (
                min_acc.min(x.get_value()),
                max_acc.max(x.get_value()),
                sum_acc + x.get_value(),
            )
        },
    );
    let avg = sum / inputs.len() as f64;
    (min.round() as u64, max.round() as u64, avg.round() as u64)
}
