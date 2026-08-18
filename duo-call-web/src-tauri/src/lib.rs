use std::process::Command;

const QIXI_URL: &str = "https://ai.xiaoyu.ski/qx";

#[tauri::command]
fn open_external_url(url: String) -> Result<(), String> {
  if url != QIXI_URL {
    return Err("不允许打开该地址".to_string());
  }

  #[cfg(target_os = "windows")]
  let result = Command::new("rundll32")
    .args(["url.dll,FileProtocolHandler", &url])
    .spawn();

  #[cfg(target_os = "macos")]
  let result = Command::new("open").arg(&url).spawn();

  #[cfg(target_os = "linux")]
  let result = Command::new("xdg-open").arg(&url).spawn();

  #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
  let result: std::io::Result<std::process::Child> = Err(std::io::Error::new(
    std::io::ErrorKind::Unsupported,
    "当前平台不支持打开外部浏览器",
  ));

  result
    .map(|_| ())
    .map_err(|error| format!("无法打开系统浏览器: {error}"))
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![open_external_url])
    .setup(|app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }
      Ok(())
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
