// Zero-JavaScript Web Server for CENTL
// Free Computation Foundation - Apache-2.0

pub mod handler;
pub mod template;

use std::fs;
use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::path::Path;
use std::sync::{Arc, Mutex};
use std::thread;
use handler::{handle_command, render_full_page, AppState};
use template::render_centl_work_area;
use crate::engine::Session;

pub fn start_server(port: u16, site_dir: &str) -> std::io::Result<()> {
    let addr = format!("127.0.0.1:{}", port);
    let listener = TcpListener::bind(&addr)?;
    println!("============================================================");
    println!("CENTL Hub & Zero-JS Web Application running at http://{}", addr);
    println!("Serving static files from: {}", site_dir);
    println!("No JavaScript required. Exact mathematics & Erdős–Straus hunt active.");
    println!("============================================================");

    let state = Arc::new(Mutex::new(AppState {
        session: Session::new(),
    }));

    let site_path = Arc::new(site_dir.to_string());

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let state_clone = Arc::clone(&state);
                let site_clone = Arc::clone(&site_path);
                thread::spawn(move || {
                    let _ = handle_connection(stream, state_clone, &site_clone);
                });
            }
            Err(e) => {
                eprintln!("Connection error: {}", e);
            }
        }
    }
    Ok(())
}

fn handle_connection(mut stream: TcpStream, state: Arc<Mutex<AppState>>, site_dir: &str) -> std::io::Result<()> {
    let mut buffer = [0u8; 16384];
    let bytes_read = stream.read(&mut buffer)?;
    if bytes_read == 0 {
        return Ok(());
    }

    let request_str = String::from_utf8_lossy(&buffer[..bytes_read]);
    let mut lines = request_str.lines();
    let first_line = match lines.next() {
        Some(line) => line,
        None => return Ok(()),
    };

    let parts: Vec<&str> = first_line.split_whitespace().collect();
    if parts.len() < 2 {
        return Ok(());
    }

    let method = parts[0];
    let raw_path = parts[1];
    let path = raw_path.split('?').next().unwrap_or("/");

    // Extract POST form body if POST
    let mut post_cmd = String::new();
    if method == "POST" {
        if let Some(body_start) = request_str.find("\r\n\r\n") {
            let body = &request_str[body_start + 4..];
            post_cmd = extract_form_value(body, "cmd");
        }
    } else if let Some(query_idx) = raw_path.find('?') {
        let query = &raw_path[query_idx + 1..];
        post_cmd = extract_form_value(query, "cmd");
    }

    // Live work area endpoints: "/" or "/index.html" or "/hub" or "/hub.html"
    if path == "/" || path == "/index.html" || path == "/hub" || path == "/hub.html" {
        let mut app_state = state.lock().unwrap();
        let (last_res, last_err, last_phys, last_hunt) = handle_command(&post_cmd, &mut app_state);

        let work_area = render_centl_work_area(
            &post_cmd,
            last_res.as_ref(),
            last_err.as_deref(),
            last_phys.as_ref(),
            last_hunt.as_ref(),
            &app_state.session,
            "/",
        );

        let home_sections = r#"
        <div class="hub-pathways">
          <section class="hub-card">
            <h3>Exact Scientific & Mathematics Hub</h3>
            <p>CENTL computes exact integers, fractions, and symbolic calculus directly. No unqualified approximations.</p>
            <p class="card-links"><a href="centl.html">About CENTL</a> · <a href="manuals/numerics.html">Numerical Contract</a></p>
          </section>
          <section class="hub-card">
            <h3>Erdős–Straus Program & Public Hunt</h3>
            <p>Join the public hunt for 3-Egyptian fraction decompositions, certificates, and content-addressed findings.</p>
            <p class="card-links"><a href="research-erdos-straus.html">Research Program</a> · <a href="research-erdos-straus.html#es-hunt">Public Hunt</a></p>
          </section>
          <section class="hub-card">
            <h3>Field Manuals & Onboarding</h3>
            <p>Dedicated guides for mathematicians, physicists, developers, and researchers.</p>
            <p class="card-links"><a href="docs.html">Documentation Portal</a> · <a href="manuals/install.html">Installation</a></p>
          </section>
          <section class="hub-card">
            <h3>Preservation & The Bazaar</h3>
            <p>Open science, mirror archives, and public funding sponsorship for serious computation.</p>
            <p class="card-links"><a href="about.html">About FCF</a> · <a href="funding.html">Funding</a> · <a href="mirrors.html">The Bazaar</a></p>
          </section>
        </div>
        "#;

        let full_content = format!("{}\n{}", work_area, home_sections);
        let full_html = render_full_page(&full_content, "CENTL Work Area", "");

        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            full_html.len(),
            full_html
        );
        stream.write_all(response.as_bytes())?;
        return Ok(());
    }

    // Serve static files from site directory
    let clean_path = path.trim_start_matches('/');
    let target_file = Path::new(site_dir).join(clean_path);

    if target_file.is_file() {
        let content_type = get_mime_type(&target_file);
        if let Ok(data) = fs::read(&target_file) {
            let header = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: {}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
                content_type,
                data.len()
            );
            stream.write_all(header.as_bytes())?;
            stream.write_all(&data)?;
            return Ok(());
        }
    }

    // 404 Fallback
    let not_found = "<h1>404 Not Found</h1><p><a href=\"/\">Return to CENTL Hub</a></p>";
    let response = format!(
        "HTTP/1.1 404 NOT FOUND\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
        not_found.len(),
        not_found
    );
    stream.write_all(response.as_bytes())?;
    Ok(())
}

fn extract_form_value(body: &str, key: &str) -> String {
    for pair in body.split('&') {
        if let Some((k, v)) = pair.split_once('=') {
            if k == key {
                return url_decode(v);
            }
        }
    }
    String::new()
}

fn url_decode(s: &str) -> String {
    let mut result = String::new();
    let mut chars = s.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '+' {
            result.push(' ');
        } else if c == '%' {
            let h1 = chars.next().unwrap_or('0');
            let h2 = chars.next().unwrap_or('0');
            if let Ok(byte) = u8::from_str_radix(&format!("{}{}", h1, h2), 16) {
                result.push(byte as char);
            }
        } else {
            result.push(c);
        }
    }
    result
}

fn get_mime_type(path: &Path) -> &'static str {
    match path.extension().and_then(|e| e.to_str()) {
        Some("html") | Some("htm") => "text/html; charset=utf-8",
        Some("css") => "text/css; charset=utf-8",
        Some("png") => "image/png",
        Some("jpg") | Some("jpeg") => "image/jpeg",
        Some("svg") => "image/svg+xml",
        Some("txt") => "text/plain; charset=utf-8",
        Some("json") => "application/json",
        Some("xml") => "application/xml",
        _ => "application/octet-stream",
    }
}
