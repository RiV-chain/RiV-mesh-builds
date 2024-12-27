use std::sync::{Arc};
use std::thread;
use tauri::Manager;
use std::time::Duration;
use reqwest;

#[tauri::command]
fn greet(name: &str) -> String {
    format!("{}", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![greet])
        .setup(|app| {
            let main_window = app.get_webview_window("main").expect("Failed to get main window");

            // Retrieve the URL from tauri.conf.json
            let config = app.config();
            if let Some(dev_url) = config.build.dev_url.as_ref() {
                let url = Arc::new(dev_url.to_string());
                let window_clone = main_window.clone();

                // Start monitoring the URL in a separate thread
                thread::spawn(move || {
                    loop {

                        // Check if the URL is reachable using reqwest
                        let response = reqwest::blocking::get(&*url);

                        if response.is_err() || !response.unwrap().status().is_success() {
                            // If unreachable, reload the frontend page
                            window_clone.eval(&format!("window.location.replace('{}');window.location.reload();", url)).unwrap_or_else(|e| {
                                eprintln!("Failed to evaluate script for reload: {}", e);
                            });
                        }

                        // Wait for 5 seconds before checking again
                        thread::sleep(Duration::from_secs(5));
                    }
                });
            }

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
