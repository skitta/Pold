#[derive(serde::Serialize, serde::Deserialize)]
pub struct InputData {
    key: String,
    name: String,
    volumn: u8,
    value: f64,
    modified_volumn: Option<u64>,
}

impl InputData {
    pub fn parse_imagej_line(line: &str) -> Option<Self> {
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() == 2 {
            let key = parts[0].to_string();
            let value = parts[1].parse::<f64>().ok()?;
            Some(Self {
                key: key.clone(),
                name: key,
                volumn: 0,
                value,
                modified_volumn: None,
            })
        } else {
            None
        }
    }

    fn value_per_volumn(&self) -> Option<u64> {
        if self.volumn == 0 {
            return None;
        }
        Some((self.value / self.volumn as f64).round() as u64)
    }

    pub fn calc_modified_volumn(&mut self, target_value: u64) {
        self.modified_volumn = self.value_per_volumn().map(|value| target_value / value);
    }

    pub fn get_value(&self) -> f64 {
        self.value
    }
}
