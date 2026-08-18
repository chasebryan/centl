// Zero-JavaScript Web Server for CENTL
// Free Computation Foundation - Apache-2.0

pub mod handler;
pub mod template;

use crate::engine::Session;
use handler::{handle_command, render_full_page, AppState};
use std::collections::HashMap;
use std::env;
use std::fs::{self, File};
use std::io::{self, Read, Write};
use std::net::{TcpListener, TcpStream};
use std::path::{Component, Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use template::render_centl_work_area;

const MAX_HEADER_BYTES: usize = 16 * 1024;
const MAX_BODY_BYTES: usize = 32 * 1024;
const MAX_HISTORY_ENTRIES: usize = 4;
const MAX_SESSIONS: usize = 1024;
const MAX_FLASHES: usize = 2048;
const SESSION_TTL: Duration = Duration::from_secs(2 * 60 * 60);
const FLASH_TTL: Duration = Duration::from_secs(60);
const SESSION_COOKIE: &str = "centl_sid";

#[derive(Debug)]
struct HttpRequest {
    method: String,
    target: String,
    headers: HashMap<String, String>,
    body: Vec<u8>,
}

struct SessionRecord {
    state: Arc<Mutex<AppState>>,
    last_seen: Instant,
}

struct FlashRecord {
    session_id: String,
    work_area_html: String,
    created: Instant,
}

struct ServerState {
    sessions: Mutex<HashMap<String, SessionRecord>>,
    flashes: Mutex<HashMap<String, FlashRecord>>,
    next_token: AtomicU64,
}

impl ServerState {
    fn new() -> Self {
        Self {
            sessions: Mutex::new(HashMap::new()),
            flashes: Mutex::new(HashMap::new()),
            next_token: AtomicU64::new(1),
        }
    }

    fn session_for(&self, requested_id: Option<&str>) -> (String, Arc<Mutex<AppState>>, bool) {
        let now = Instant::now();
        let mut sessions = self
            .sessions
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        sessions.retain(|_, record| now.duration_since(record.last_seen) < SESSION_TTL);

        if let Some(id) = requested_id.filter(|id| valid_token(id)) {
            if let Some(record) = sessions.get_mut(id) {
                record.last_seen = now;
                return (id.to_string(), Arc::clone(&record.state), false);
            }
        }

        if sessions.len() >= MAX_SESSIONS {
            if let Some(oldest) = sessions
                .iter()
                .min_by_key(|(_, record)| record.last_seen)
                .map(|(id, _)| id.clone())
            {
                sessions.remove(&oldest);
            }
        }

        let id = self.new_token();
        let state = Arc::new(Mutex::new(AppState {
            session: Session::new(),
        }));
        sessions.insert(
            id.clone(),
            SessionRecord {
                state: Arc::clone(&state),
                last_seen: now,
            },
        );
        (id, state, true)
    }

    fn store_flash(&self, session_id: &str, work_area_html: String) -> String {
        let now = Instant::now();
        let mut flashes = self
            .flashes
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        flashes.retain(|_, record| now.duration_since(record.created) < FLASH_TTL);
        if flashes.len() >= MAX_FLASHES {
            if let Some(oldest) = flashes
                .iter()
                .min_by_key(|(_, record)| record.created)
                .map(|(token, _)| token.clone())
            {
                flashes.remove(&oldest);
            }
        }
        let token = self.new_token();
        flashes.insert(
            token.clone(),
            FlashRecord {
                session_id: session_id.to_string(),
                work_area_html,
                created: now,
            },
        );
        token
    }

    fn take_flash(&self, token: &str, session_id: &str) -> Option<String> {
        if !valid_token(token) {
            return None;
        }
        let now = Instant::now();
        let mut flashes = self
            .flashes
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        flashes.retain(|_, record| now.duration_since(record.created) < FLASH_TTL);
        let record = flashes.remove(token)?;
        (record.session_id == session_id).then_some(record.work_area_html)
    }

    fn new_token(&self) -> String {
        let mut bytes = [0u8; 16];
        if File::open("/dev/urandom")
            .and_then(|mut file| file.read_exact(&mut bytes))
            .is_err()
        {
            let counter = self.next_token.fetch_add(1, Ordering::Relaxed) as u128;
            let nanos = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos();
            let mixed = nanos
                ^ counter.rotate_left(37)
                ^ ((std::process::id() as u128) << 64);
            bytes.copy_from_slice(&mixed.to_be_bytes());
        }
        bytes.iter().map(|byte| format!("{byte:02x}")).collect()
    }
}

pub fn start_server(port: u16, site_dir: &str) -> io::Result<()> {
    let bind_host = env::var("CENTL_BIND_HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let addr = format!("{}:{}", bind_host, port);
    let listener = TcpListener::bind(&addr)?;
    println!("============================================================");
    println!("CENTL Hub & Zero-JS Web Application running at http://{}", addr);
    println!("Serving static files from: {}", site_dir);
    println!("Build commit: {}", build_commit());
    println!("No JavaScript required. Exact mathematics & Erdős–Straus hunt active.");
    println!("============================================================");

    let state = Arc::new(ServerState::new());
    let site_path = Arc::new(site_dir.to_string());

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let state_clone = Arc::clone(&state);
                let site_clone = Arc::clone(&site_path);
                thread::spawn(move || {
                    if let Err(error) = handle_connection(stream, state_clone, &site_clone) {
                        eprintln!("CENTL web request failed: {}", error);
                    }
                });
            }
            Err(error) => eprintln!("Connection error: {}", error),
        }
    }
    Ok(())
}

fn handle_connection(
    mut stream: TcpStream,
    server_state: Arc<ServerState>,
    site_dir: &str,
) -> io::Result<()> {
    stream.set_read_timeout(Some(Duration::from_secs(8)))?;
    stream.set_write_timeout(Some(Duration::from_secs(15)))?;

    let request = match read_http_request(&mut stream) {
        Ok(Some(request)) => request,
        Ok(None) => return Ok(()),
        Err(error) => {
            let body = format!("Bad request: {}", error);
            return write_text_response(&mut stream, 400, "Bad Request", &body, &[], false);
        }
    };

    let method = request.method.as_str();
    let raw_path = request.target.as_str();
    let path = raw_path.split('?').next().unwrap_or("/");
    let is_head = method == "HEAD";

    if (method == "GET" || is_head) && path == "/__centl_origin" {
        let body = format!("centl-web {}\n", build_commit());
        return write_text_response(
            &mut stream,
            200,
            "OK",
            &body,
            &[("Cache-Control", "no-store".to_string())],
            is_head,
        );
    }

    if method == "POST" && (path == "/" || path == "/index.html") {
        return write_redirect(&mut stream, 307, "Temporary Redirect", "/hub");
    }

    if (method == "GET" || is_head) && (path == "/" || path == "/index.html") {
        return serve_static_file(&mut stream, site_dir, "index.html", is_head);
    }

    if path == "/hub" || path == "/hub.html" {
        if method != "GET" && method != "HEAD" && method != "POST" {
            return write_text_response(
                &mut stream,
                405,
                "Method Not Allowed",
                "Method not allowed",
                &[("Allow", "GET, HEAD, POST".to_string())],
                is_head,
            );
        }

        let requested_session = request
            .headers
            .get("cookie")
            .and_then(|header| cookie_value(header, SESSION_COOKIE));
        let (session_id, session_state, is_new_session) =
            server_state.session_for(requested_session.as_deref());

        if method == "POST" {
            let body = String::from_utf8_lossy(&request.body);
            let post_cmd = extract_form_value(&body, "cmd");
            let work_area = {
                let mut app_state = session_state
                    .lock()
                    .unwrap_or_else(|poisoned| poisoned.into_inner());
                let (last_result, last_error, last_physics, last_hunt) =
                    handle_command(&post_cmd, &mut app_state);
                trim_history(&mut app_state);
                let input_value = if last_error.is_some() {
                    post_cmd.as_str()
                } else {
                    ""
                };
                render_centl_work_area(
                    input_value,
                    last_result.as_ref(),
                    last_error.as_deref(),
                    last_physics.as_ref(),
                    last_hunt.as_ref(),
                    &app_state.session,
                    "/hub",
                )
            };

            let view_token = server_state.store_flash(&session_id, work_area);
            let location = format!("/hub?view={}#centl-console", view_token);
            let mut headers = Vec::new();
            if is_new_session {
                headers.push((
                    "Set-Cookie",
                    session_cookie_header(&session_id, request_is_https(&request)),
                ));
            }
            return write_redirect_with_headers(
                &mut stream,
                303,
                "See Other",
                &location,
                &headers,
            );
        }

        let work_area = if is_head {
            render_pristine_work_area()
        } else {
            let view_token = raw_path
                .find('?')
                .map(|index| extract_form_value(&raw_path[index + 1..], "view"))
                .unwrap_or_default();
            if !view_token.is_empty() {
                server_state.take_flash(&view_token, &session_id)
            } else {
                None
            }
            .unwrap_or_else(|| {
                let mut app_state = session_state
                    .lock()
                    .unwrap_or_else(|poisoned| poisoned.into_inner());
                reset_session(&mut app_state);
                render_centl_work_area(
                    "",
                    None,
                    None,
                    None,
                    None,
                    &app_state.session,
                    "/hub",
                )
            })
        };

        let full_html = render_hub_page(&work_area);
        let mut headers = vec![
            ("Cache-Control", "no-store, private, max-age=0".to_string()),
            ("Pragma", "no-cache".to_string()),
            ("Expires", "0".to_string()),
            ("X-Content-Type-Options", "nosniff".to_string()),
            ("Referrer-Policy", "same-origin".to_string()),
        ];
        if is_new_session {
            headers.push((
                "Set-Cookie",
                session_cookie_header(&session_id, request_is_https(&request)),
            ));
        }
        return write_html_response(&mut stream, 200, "OK", &full_html, &headers, is_head);
    }

    if method != "GET" && !is_head {
        return write_text_response(
            &mut stream,
            405,
            "Method Not Allowed",
            "Method not allowed",
            &[("Allow", "GET, HEAD".to_string())],
            is_head,
        );
    }

    let clean_path = path.trim_start_matches('/');
    if safe_relative_path(clean_path).is_none() {
        return write_text_response(
            &mut stream,
            403,
            "Forbidden",
            "Forbidden",
            &[],
            is_head,
        );
    }

    let target_file = Path::new(site_dir).join(clean_path);
    if target_file.is_file() {
        return serve_file_path(&mut stream, &target_file, is_head);
    }

    write_text_response(
        &mut stream,
        404,
        "Not Found",
        "404 Not Found\n",
        &[],
        is_head,
    )
}

fn render_pristine_work_area() -> String {
    let session = Session::new();
    render_centl_work_area("", None, None, None, None, &session, "/hub")
}

fn render_hub_page(work_area: &str) -> String {
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
    render_full_page(&full_content, "CENTL Work Area", "")
}

fn read_http_request(stream: &mut TcpStream) -> io::Result<Option<HttpRequest>> {
    let mut data = Vec::with_capacity(4096);
    let mut scratch = [0u8; 4096];
    let header_end = loop {
        let read = stream.read(&mut scratch)?;
        if read == 0 {
            if data.is_empty() {
                return Ok(None);
            }
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "connection closed before request headers completed",
            ));
        }
        data.extend_from_slice(&scratch[..read]);
        if let Some(index) = find_bytes(&data, b"\r\n\r\n") {
            break index + 4;
        }
        if data.len() > MAX_HEADER_BYTES {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "request headers exceed limit",
            ));
        }
    };

    if header_end > MAX_HEADER_BYTES {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "request headers exceed limit",
        ));
    }

    let header_text = std::str::from_utf8(&data[..header_end]).map_err(|_| {
        io::Error::new(
            io::ErrorKind::InvalidData,
            "request headers are not valid UTF-8",
        )
    })?;
    let mut lines = header_text[..header_text.len() - 4].split("\r\n");
    let request_line = lines
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing request line"))?;
    let mut request_parts = request_line.split_whitespace();
    let method = request_parts
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing method"))?
        .to_string();
    let target = request_parts
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing request target"))?
        .to_string();
    let version = request_parts
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing HTTP version"))?;
    if !version.starts_with("HTTP/1.") {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "unsupported HTTP version",
        ));
    }

    let mut headers = HashMap::new();
    for line in lines {
        let Some((name, value)) = line.split_once(':') else {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "malformed request header",
            ));
        };
        headers.insert(name.trim().to_ascii_lowercase(), value.trim().to_string());
    }

    if headers
        .get("transfer-encoding")
        .is_some_and(|value| !value.eq_ignore_ascii_case("identity"))
    {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "chunked request bodies are not supported",
        ));
    }

    let content_length = match headers.get("content-length") {
        Some(value) => value.parse::<usize>().map_err(|_| {
            io::Error::new(io::ErrorKind::InvalidData, "invalid Content-Length")
        })?,
        None => 0,
    };
    if content_length > MAX_BODY_BYTES {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "request body exceeds limit",
        ));
    }

    let required = header_end + content_length;
    while data.len() < required {
        let read = stream.read(&mut scratch)?;
        if read == 0 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "connection closed before request body completed",
            ));
        }
        data.extend_from_slice(&scratch[..read]);
        if data.len() > MAX_HEADER_BYTES + MAX_BODY_BYTES {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "request exceeds limit",
            ));
        }
    }

    Ok(Some(HttpRequest {
        method,
        target,
        headers,
        body: data[header_end..required].to_vec(),
    }))
}

fn find_bytes(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    haystack
        .windows(needle.len())
        .position(|window| window == needle)
}

fn trim_history(state: &mut AppState) {
    let len = state.session.history.len();
    if len > MAX_HISTORY_ENTRIES {
        state.session.history.drain(..len - MAX_HISTORY_ENTRIES);
    }
}

fn reset_session(state: &mut AppState) {
    state.session = Session::new();
}

fn cookie_value(cookie_header: &str, name: &str) -> Option<String> {
    cookie_header.split(';').find_map(|part| {
        let (key, value) = part.trim().split_once('=')?;
        (key == name).then(|| value.to_string())
    })
}

fn valid_token(id: &str) -> bool {
    id.len() == 32 && id.bytes().all(|byte| byte.is_ascii_hexdigit())
}

fn request_is_https(request: &HttpRequest) -> bool {
    request
        .headers
        .get("x-forwarded-proto")
        .is_some_and(|value| value.eq_ignore_ascii_case("https"))
}

fn session_cookie_header(session_id: &str, secure: bool) -> String {
    let secure_attribute = if secure { "; Secure" } else { "" };
    format!(
        "{}={}; Path=/; HttpOnly; SameSite=Lax; Max-Age={}{}",
        SESSION_COOKIE,
        session_id,
        SESSION_TTL.as_secs(),
        secure_attribute
    )
}

fn extract_form_value(body: &str, key: &str) -> String {
    for pair in body.split('&') {
        if let Some((raw_key, raw_value)) = pair.split_once('=') {
            if url_decode(raw_key) == key {
                return url_decode(raw_value);
            }
        }
    }
    String::new()
}

fn url_decode(value: &str) -> String {
    let bytes = value.as_bytes();
    let mut decoded = Vec::with_capacity(bytes.len());
    let mut index = 0;
    while index < bytes.len() {
        match bytes[index] {
            b'+' => {
                decoded.push(b' ');
                index += 1;
            }
            b'%' if index + 2 < bytes.len() => {
                if let (Some(high), Some(low)) =
                    (hex_value(bytes[index + 1]), hex_value(bytes[index + 2]))
                {
                    decoded.push((high << 4) | low);
                    index += 3;
                } else {
                    decoded.push(bytes[index]);
                    index += 1;
                }
            }
            byte => {
                decoded.push(byte);
                index += 1;
            }
        }
    }
    String::from_utf8_lossy(&decoded).into_owned()
}

fn hex_value(byte: u8) -> Option<u8> {
    match byte {
        b'0'..=b'9' => Some(byte - b'0'),
        b'a'..=b'f' => Some(byte - b'a' + 10),
        b'A'..=b'F' => Some(byte - b'A' + 10),
        _ => None,
    }
}

fn safe_relative_path(path: &str) -> Option<PathBuf> {
    if path.is_empty() {
        return None;
    }
    let candidate = Path::new(path);
    if candidate
        .components()
        .all(|component| matches!(component, Component::Normal(_)))
    {
        Some(candidate.to_path_buf())
    } else {
        None
    }
}

fn serve_static_file(
    stream: &mut TcpStream,
    site_dir: &str,
    path: &str,
    head: bool,
) -> io::Result<()> {
    let target = Path::new(site_dir).join(path);
    if !target.is_file() {
        return write_text_response(stream, 404, "Not Found", "404 Not Found\n", &[], head);
    }
    serve_file_path(stream, &target, head)
}

fn serve_file_path(stream: &mut TcpStream, target: &Path, head: bool) -> io::Result<()> {
    let data = fs::read(target)?;
    let content_type = get_mime_type(target);
    let headers = [
        ("X-Content-Type-Options", "nosniff".to_string()),
        ("Cache-Control", static_cache_control(target).to_string()),
    ];
    write_response(
        stream,
        200,
        "OK",
        content_type,
        &data,
        &headers,
        head,
    )
}

fn write_redirect(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    location: &str,
) -> io::Result<()> {
    write_redirect_with_headers(stream, status, reason, location, &[])
}

fn write_redirect_with_headers(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    location: &str,
    extra_headers: &[(&str, String)],
) -> io::Result<()> {
    let mut headers = vec![
        ("Location", location.to_string()),
        ("Cache-Control", "no-store".to_string()),
    ];
    headers.extend(
        extra_headers
            .iter()
            .map(|(name, value)| (*name, value.clone())),
    );
    write_response(
        stream,
        status,
        reason,
        "text/plain; charset=utf-8",
        &[],
        &headers,
        false,
    )
}

fn write_html_response(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    html: &str,
    headers: &[(&str, String)],
    head: bool,
) -> io::Result<()> {
    write_response(
        stream,
        status,
        reason,
        "text/html; charset=utf-8",
        html.as_bytes(),
        headers,
        head,
    )
}

fn write_text_response(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    text: &str,
    headers: &[(&str, String)],
    head: bool,
) -> io::Result<()> {
    write_response(
        stream,
        status,
        reason,
        "text/plain; charset=utf-8",
        text.as_bytes(),
        headers,
        head,
    )
}

fn write_response(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    content_type: &str,
    body: &[u8],
    headers: &[(&str, String)],
    head: bool,
) -> io::Result<()> {
    let mut response_head = format!(
        "HTTP/1.1 {} {}\r\nContent-Type: {}\r\nContent-Length: {}\r\nConnection: close\r\nX-CENTL-Origin: rust\r\nX-CENTL-Build: {}\r\n",
        status,
        reason,
        content_type,
        body.len(),
        build_commit()
    );
    for (name, value) in headers {
        response_head.push_str(name);
        response_head.push_str(": ");
        response_head.push_str(value);
        response_head.push_str("\r\n");
    }
    response_head.push_str("\r\n");
    stream.write_all(response_head.as_bytes())?;
    if !head {
        stream.write_all(body)?;
    }
    stream.flush()
}

fn build_commit() -> String {
    env::var("CENTL_BUILD_COMMIT")
        .ok()
        .filter(|value| {
            !value.is_empty()
                && value.len() <= 64
                && value
                    .bytes()
                    .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-' || byte == b'_')
        })
        .unwrap_or_else(|| "unknown".to_string())
}

fn static_cache_control(path: &Path) -> &'static str {
    match path.extension().and_then(|extension| extension.to_str()) {
        Some("css") | Some("png") | Some("jpg") | Some("jpeg") | Some("svg") => {
            "public, max-age=300"
        }
        _ => "no-cache, max-age=0",
    }
}

fn get_mime_type(path: &Path) -> &'static str {
    match path.extension().and_then(|extension| extension.to_str()) {
        Some("html") | Some("htm") => "text/html; charset=utf-8",
        Some("css") => "text/css; charset=utf-8",
        Some("js") => "text/javascript; charset=utf-8",
        Some("png") => "image/png",
        Some("jpg") | Some("jpeg") => "image/jpeg",
        Some("webp") => "image/webp",
        Some("svg") => "image/svg+xml",
        Some("txt") => "text/plain; charset=utf-8",
        Some("json") => "application/json",
        Some("xml") => "application/xml",
        Some("ico") => "image/x-icon",
        _ => "application/octet-stream",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::engine::HistoryEntry;

    #[test]
    fn percent_decoder_preserves_utf8_math() {
        assert_eq!(url_decode("approx%28%CF%80%2C+50%29"), "approx(π, 50)");
    }

    #[test]
    fn form_decoder_handles_plus_and_escaped_plus() {
        assert_eq!(
            extract_form_value("cmd=1%2F3+%2B+5%2F7", "cmd"),
            "1/3 + 5/7"
        );
    }

    #[test]
    fn static_paths_reject_parent_traversal() {
        assert!(safe_relative_path("assets/fcf-centl-banner.png").is_some());
        assert!(safe_relative_path("../Cargo.toml").is_none());
        assert!(safe_relative_path("manuals/../../Cargo.toml").is_none());
    }

    #[test]
    fn tokens_are_strict_hex_values() {
        assert!(valid_token("0123456789abcdef0123456789abcdef"));
        assert!(!valid_token("../not-a-session"));
        assert!(!valid_token("0123456789abcdef"));
    }

    #[test]
    fn flashes_are_one_time_and_session_scoped() {
        let state = ServerState::new();
        let token = state.store_flash("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "result".to_string());
        assert!(state
            .take_flash(&token, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
            .is_none());
        let token = state.store_flash("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "result".to_string());
        assert_eq!(
            state.take_flash(&token, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
            Some("result".to_string())
        );
        assert!(state
            .take_flash(&token, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
            .is_none());
    }

    #[test]
    fn reset_session_clears_saved_calculations() {
        let mut state = AppState {
            session: Session::new(),
        };
        state.session.history.push(HistoryEntry {
            command: "22 + 22".to_string(),
            result: "44".to_string(),
            exact_repr: None,
            approximate_repr: None,
            execution_micros: 1,
            success: true,
        });
        reset_session(&mut state);
        assert!(state.session.history.is_empty());
    }

    #[test]
    fn pristine_work_area_contains_no_history_rows() {
        let html = render_pristine_work_area();
        assert!(html.contains("CENTL exact mathematical interpreter ready."));
        assert!(!html.contains("history-item"));
    }
}
